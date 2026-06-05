import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/router/app_router.dart';
import '../../../shared/providers/roadmap_provider.dart';
import '../../../shared/widgets/stepup_button.dart';
import '../../../shared/widgets/stepup_input.dart';

class CreateRoadmapScreen extends ConsumerStatefulWidget {
  const CreateRoadmapScreen({super.key});
  @override
  ConsumerState<CreateRoadmapScreen> createState() => _CreateRoadmapScreenState();
}

class _CreateRoadmapScreenState extends ConsumerState<CreateRoadmapScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _selectedType = 'study';
  bool _examMode = false;
  DateTime? _deadline;
  String _source = 'manual'; // manual / ai
  String _titleError = '';

  final _types = [
    ('study', '📚', 'Study'),
    ('gym', '💪', 'Fitness'),
    ('work', '💼', 'Work'),
    ('custom', '🎯', 'Custom'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {
          _source = _tabController.index == 0 ? 'manual' : 'ai';
        }));
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDeadline() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(primary: AppColors.brand),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _deadline = picked);
  }

  Future<void> _create() async {
    if (_titleCtrl.text.trim().isEmpty) {
      setState(() => _titleError = 'Title is required');
      return;
    }
    setState(() => _titleError = '');
    final payload = {
      'title': _titleCtrl.text.trim(),
      'description': _descCtrl.text.trim(),
      'type': _selectedType,
      'source': _source,
      'examMode': _examMode,
      if (_deadline != null) 'deadline': _deadline!.toIso8601String(),
    };
    final roadmap = await ref.read(roadmapProvider.notifier).createRoadmap(payload);
    if (roadmap != null && mounted) {
      context.go('${AppRoutes.map}/${roadmap.id}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(roadmapProvider).isLoading;
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: Text('New Roadmap', style: AppTextStyles.h3),
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.brand,
          indicatorWeight: 2,
          labelColor: AppColors.brand,
          unselectedLabelColor: AppColors.textSecondary,
          labelStyle: AppTextStyles.label,
          tabs: const [
            Tab(text: 'MANUAL'),
            Tab(text: 'AI GENERATE'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _ManualForm(
            titleCtrl: _titleCtrl,
            descCtrl: _descCtrl,
            types: _types,
            selectedType: _selectedType,
            examMode: _examMode,
            deadline: _deadline,
            titleError: _titleError,
            isLoading: isLoading,
            onTypeSelected: (t) => setState(() => _selectedType = t),
            onExamModeChanged: (v) => setState(() => _examMode = v),
            onDeadlineTap: _pickDeadline,
            onSubmit: _create,
          ),
          _AIGenerateForm(
            isLoading: isLoading,
            onSubmit: _create,
            titleCtrl: _titleCtrl,
            types: _types,
            selectedType: _selectedType,
            onTypeSelected: (t) => setState(() => _selectedType = t),
          ),
        ],
      ),
    );
  }
}

class _ManualForm extends StatelessWidget {
  final TextEditingController titleCtrl;
  final TextEditingController descCtrl;
  final List<(String, String, String)> types;
  final String selectedType;
  final bool examMode;
  final DateTime? deadline;
  final String titleError;
  final bool isLoading;
  final ValueChanged<String> onTypeSelected;
  final ValueChanged<bool> onExamModeChanged;
  final VoidCallback onDeadlineTap;
  final VoidCallback onSubmit;

  const _ManualForm({
    required this.titleCtrl, required this.descCtrl, required this.types,
    required this.selectedType, required this.examMode, required this.deadline,
    required this.titleError, required this.isLoading,
    required this.onTypeSelected, required this.onExamModeChanged,
    required this.onDeadlineTap, required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.md),
          StepUpInput(
            label: 'Roadmap Title',
            hint: 'e.g. Master React in 30 Days',
            controller: titleCtrl,
            errorText: titleError.isEmpty ? null : titleError,
          ).animate().fadeIn(delay: 100.ms),
          const SizedBox(height: AppSpacing.base),
          StepUpInput(
            label: 'Description (optional)',
            hint: 'What is this roadmap about?',
            controller: descCtrl,
            maxLines: 3,
          ).animate().fadeIn(delay: 150.ms),
          const SizedBox(height: AppSpacing.xl),
          Text('Category', style: AppTextStyles.label).animate().fadeIn(delay: 200.ms),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: types.map((t) {
              final (id, emoji, label) = t;
              final isSelected = selectedType == id;
              return GestureDetector(
                onTap: () => onTypeSelected(id),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: isSelected ? AppColors.brandGradient : null,
                    color: isSelected ? null : AppColors.bgCard,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                    border: Border.all(
                      color: isSelected ? Colors.transparent : AppColors.border,
                    ),
                    boxShadow: isSelected ? [
                      BoxShadow(color: AppColors.brand.withOpacity(0.3), blurRadius: 8),
                    ] : null,
                  ),
                  child: Text('$emoji  $label',
                      style: AppTextStyles.bodyMedium.copyWith(
                          color: isSelected ? Colors.white : AppColors.textSecondary)),
                ),
              );
            }).toList(),
          ).animate().fadeIn(delay: 200.ms),
          const SizedBox(height: AppSpacing.xl),
          // Exam mode toggle
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Exam Mode', style: AppTextStyles.bodyLarge),
                    Text('Locks access until deadline', style: AppTextStyles.bodySmall),
                  ],
                ),
              ),
              Switch(value: examMode, onChanged: onExamModeChanged,
                  activeColor: AppColors.brand),
            ],
          ).animate().fadeIn(delay: 280.ms),
          const Divider(color: AppColors.border, height: AppSpacing.xl),
          // Deadline
          GestureDetector(
            onTap: onDeadlineTap,
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.base),
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_outlined,
                      color: AppColors.textSecondary, size: 20),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Deadline', style: AppTextStyles.label),
                        Text(
                          deadline != null
                              ? '${deadline!.day}/${deadline!.month}/${deadline!.year}'
                              : 'No deadline set',
                          style: AppTextStyles.bodyMedium.copyWith(
                              color: deadline != null
                                  ? AppColors.textPrimary
                                  : AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textMuted),
                ],
              ),
            ),
          ).animate().fadeIn(delay: 330.ms),
          const SizedBox(height: AppSpacing.xxxl),
          StepUpButton(
            label: 'Create Roadmap 🚀',
            isLoading: isLoading,
            onPressed: onSubmit,
          ).animate().fadeIn(delay: 400.ms),
        ],
      ),
    );
  }
}

class _AIGenerateForm extends StatefulWidget {
  final bool isLoading;
  final VoidCallback onSubmit;
  final TextEditingController titleCtrl;
  final List<(String, String, String)> types;
  final String selectedType;
  final ValueChanged<String> onTypeSelected;

  const _AIGenerateForm({
    required this.isLoading, required this.onSubmit, required this.titleCtrl,
    required this.types, required this.selectedType, required this.onTypeSelected,
  });

  @override
  State<_AIGenerateForm> createState() => _AIGenerateFormState();
}

class _AIGenerateFormState extends State<_AIGenerateForm> {
  final _promptCtrl = TextEditingController();

  @override
  void dispose() { _promptCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.base),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1A1040), Color(0xFF12121A)],
              ),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(color: AppColors.brand.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Text('🤖', style: TextStyle(fontSize: 28)),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    'Describe your goal and AI will generate a structured roadmap for you.',
                    style: AppTextStyles.bodySmall,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          StepUpInput(
            label: 'Goal Title',
            hint: 'e.g. Learn Python for Data Science',
            controller: widget.titleCtrl,
          ),
          const SizedBox(height: AppSpacing.base),
          StepUpInput(
            label: 'Describe your goal',
            hint:
                'e.g. I want to learn Python from scratch to do data analysis in 60 days...',
            controller: _promptCtrl,
            maxLines: 5,
          ),
          const SizedBox(height: AppSpacing.xxxl),
          StepUpButton(
            label: 'Generate with AI ✨',
            isLoading: widget.isLoading,
            onPressed: widget.onSubmit,
          ),
        ],
      ),
    );
  }
}
