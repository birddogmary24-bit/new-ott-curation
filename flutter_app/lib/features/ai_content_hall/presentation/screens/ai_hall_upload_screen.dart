import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/config/theme/app_colors.dart';
import '../../data/datasources/ai_hall_remote_datasource.dart';
import '../providers/ai_hall_provider.dart';

class AiHallUploadScreen extends ConsumerStatefulWidget {
  const AiHallUploadScreen({super.key});

  @override
  ConsumerState<AiHallUploadScreen> createState() => _AiHallUploadScreenState();
}

class _AiHallUploadScreenState extends ConsumerState<AiHallUploadScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _tagsController = TextEditingController();

  File? _videoFile;
  String _selectedContentType = 'short_video';
  String? _selectedAiTool;
  bool _isUploading = false;
  double _uploadProgress = 0;
  String? _errorMsg;

  static const contentTypes = [
    ('short_video',   '숏폼'),
    ('clip',          '클립'),
    ('trailer_remix', '트레일러 리믹스'),
    ('highlight',     '하이라이트'),
    ('fan_edit',      '팬 에디트'),
  ];

  static const aiTools = [
    'Sora', 'Runway', 'Kling', 'Pika', 'HeyGen',
    'Topaz', 'Adobe Firefly', 'Stable Video', '기타',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _pickVideo() async {
    final picker = ImagePicker();
    final video = await picker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: Duration(seconds: AppConfig.maxVideoDurationSeconds),
    );
    if (video != null) {
      setState(() => _videoFile = File(video.path));
    }
  }

  Future<void> _upload() async {
    if (!_formKey.currentState!.validate()) return;
    if (_videoFile == null) {
      setState(() => _errorMsg = '영상 파일을 선택해주세요.');
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = 0;
      _errorMsg = null;
    });

    try {
      final tags = _tagsController.text
          .split(',')
          .map((t) => t.trim())
          .where((t) => t.isNotEmpty)
          .toList();

      // 1단계: signed URL 발급
      final ds = ref.read(aiHallDataSourceProvider);
      final upload = await ds.prepareUpload(
        title: _titleController.text.trim(),
        contentType: _selectedContentType,
        durationSeconds: 30, // TODO: 실제 영상 길이 파싱
        tags: tags,
        aiToolUsed: _selectedAiTool,
      );

      setState(() => _uploadProgress = 0.1);

      // 2단계: Cloud Storage 직접 업로드
      final dio = Dio();
      await dio.put(
        upload.videoUploadUrl,
        data: _videoFile!.openRead(),
        options: Options(
          headers: {'Content-Type': 'video/mp4'},
          sendTimeout: const Duration(minutes: 10),
          receiveTimeout: const Duration(minutes: 10),
        ),
        onSendProgress: (sent, total) {
          if (total > 0) {
            setState(() => _uploadProgress = 0.1 + (sent / total) * 0.85);
          }
        },
      );

      setState(() => _uploadProgress = 0.95);

      // 3단계: 완료 알림 (모더레이션 시작)
      await ds.completeUpload(upload.contentId);
      setState(() => _uploadProgress = 1.0);

      // 피드 새로고침
      ref.read(aiHallFeedProvider.notifier).loadInitial();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('업로드 완료! AI 검토 후 피드에 노출돼요. 🎉'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
        _errorMsg = '업로드 중 오류가 발생했어요. 다시 시도해주세요.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        title: const Text('AI 콘텐츠 올리기',
          style: TextStyle(color: AppColors.textPrimaryDark, fontWeight: FontWeight.w700)),
        leading: const BackButton(color: AppColors.textPrimaryDark),
        actions: [
          if (!_isUploading)
            TextButton(
              onPressed: _upload,
              child: const Text('업로드', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
            ),
        ],
      ),
      body: _isUploading
          ? _UploadingIndicator(progress: _uploadProgress)
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 영상 선택
                    _VideoPickerButton(
                      videoFile: _videoFile,
                      onTap: _pickVideo,
                    ),
                    const SizedBox(height: 24),

                    // 제목
                    _SectionLabel('제목'),
                    TextFormField(
                      controller: _titleController,
                      style: const TextStyle(color: AppColors.textPrimaryDark),
                      decoration: _inputDecoration('AI로 만든 영상 제목을 입력하세요'),
                      maxLength: 100,
                      validator: (v) => (v?.trim().isEmpty ?? true) ? '제목을 입력해주세요.' : null,
                    ),
                    const SizedBox(height: 16),

                    // 콘텐츠 타입
                    _SectionLabel('콘텐츠 타입'),
                    Wrap(
                      spacing: 8,
                      children: contentTypes.map(((String id, String label) type) {
                        final isSelected = _selectedContentType == type.$1;
                        return ChoiceChip(
                          label: Text(type.$2),
                          selected: isSelected,
                          onSelected: (_) => setState(() => _selectedContentType = type.$1),
                          selectedColor: AppColors.accent,
                          backgroundColor: AppColors.surfaceDark,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : AppColors.textSecondaryDark,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // AI 도구
                    _SectionLabel('사용한 AI 도구 (선택)'),
                    Wrap(
                      spacing: 8,
                      children: aiTools.map((tool) {
                        final isSelected = _selectedAiTool == tool;
                        return ChoiceChip(
                          label: Text(tool),
                          selected: isSelected,
                          onSelected: (_) => setState(() {
                            _selectedAiTool = isSelected ? null : tool;
                          }),
                          selectedColor: AppColors.primary,
                          backgroundColor: AppColors.surfaceDark,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : AppColors.textSecondaryDark,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // 태그
                    _SectionLabel('태그 (선택, 쉼표로 구분)'),
                    TextFormField(
                      controller: _tagsController,
                      style: const TextStyle(color: AppColors.textPrimaryDark),
                      decoration: _inputDecoration('예: 넷플릭스, 스릴러, AI영상'),
                    ),
                    const SizedBox(height: 24),

                    // 업로드 정책 안내
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceDark,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.dividerDark),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('📋 업로드 정책',
                            style: TextStyle(color: AppColors.textPrimaryDark, fontWeight: FontWeight.w600)),
                          SizedBox(height: 8),
                          Text('• AI로 생성된 콘텐츠만 업로드 가능해요\n'
                              '• 최대 60초, 500MB 이하의 영상\n'
                              '• 업로드 후 AI 자동 검토 (1~5분 소요)\n'
                              '• 저작권 침해 콘텐츠는 즉시 삭제돼요',
                            style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 13, height: 1.6)),
                        ],
                      ),
                    ),

                    // 에러 메시지
                    if (_errorMsg != null) ...[
                      const SizedBox(height: 16),
                      Text(_errorMsg!, style: const TextStyle(color: AppColors.error)),
                    ],

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.textSecondaryDark),
      filled: true,
      fillColor: AppColors.surfaceDark,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.dividerDark),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.dividerDark),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.primary),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: const TextStyle(
        color: AppColors.textPrimaryDark,
        fontWeight: FontWeight.w600,
        fontSize: 14,
      )),
    );
  }
}

class _VideoPickerButton extends StatelessWidget {
  final File? videoFile;
  final VoidCallback onTap;

  const _VideoPickerButton({required this.videoFile, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 180,
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: videoFile != null ? AppColors.accent : AppColors.dividerDark,
            width: 2,
          ),
        ),
        child: videoFile != null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle, color: AppColors.success, size: 48),
                  const SizedBox(height: 8),
                  Text(
                    videoFile!.path.split('/').last,
                    style: const TextStyle(color: AppColors.textPrimaryDark, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  const Text('탭하여 다시 선택', style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 12)),
                ],
              )
            : const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.video_call_rounded, color: AppColors.accent, size: 56),
                  SizedBox(height: 12),
                  Text('AI 영상 선택하기', style: TextStyle(
                    color: AppColors.textPrimaryDark, fontSize: 16, fontWeight: FontWeight.w600,
                  )),
                  SizedBox(height: 4),
                  Text('최대 60초 · 500MB', style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 13)),
                ],
              ),
      ),
    );
  }
}

class _UploadingIndicator extends StatelessWidget {
  final double progress;
  const _UploadingIndicator({required this.progress});

  @override
  Widget build(BuildContext context) {
    final label = progress < 0.1 ? '업로드 준비 중...'
        : progress < 0.95 ? '영상 업로드 중...'
        : progress < 1.0 ? 'AI 검토 시작 중...'
        : '완료!';

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_upload_outlined, color: AppColors.primary, size: 64),
            const SizedBox(height: 24),
            Text(label, style: const TextStyle(
              color: AppColors.textPrimaryDark, fontSize: 18, fontWeight: FontWeight.w600,
            )),
            const SizedBox(height: 20),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.surfaceDark,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accent),
              minHeight: 6,
              borderRadius: BorderRadius.circular(3),
            ),
            const SizedBox(height: 12),
            Text(
              '${(progress * 100).toInt()}%',
              style: const TextStyle(color: AppColors.textSecondaryDark),
            ),
          ],
        ),
      ),
    );
  }
}
