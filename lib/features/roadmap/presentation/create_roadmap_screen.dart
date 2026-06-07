import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
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

class _ManualLevel {
  final TextEditingController controller;
  String proofType; // 'quiz', 'timer', 'code'
  _ManualLevel({required String title, required this.proofType})
      : controller = TextEditingController(text: title);

  void dispose() {
    controller.dispose();
  }
}

class _CreateRoadmapScreenState extends ConsumerState<CreateRoadmapScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  
  // AI Goal inputs
  final _aiGoalTitleCtrl = TextEditingController();
  final _aiGoalDescCtrl = TextEditingController();

  String _selectedType = 'study';
  bool _examMode = false;
  DateTime? _deadline;
  String _source = 'manual'; // manual / ai
  String _titleError = '';
  String _aiTitleError = '';
  
  // Manual Levels
  final List<_ManualLevel> _manualLevels = [
    _ManualLevel(title: 'Level 1: Introduction', proofType: 'quiz')
  ];

  // AI Loading & Preview States
  bool _isGeneratingAI = false;
  int _loadingMsgIdx = 0;
  Timer? _loadingTimer;
  List<Map<String, dynamic>>? _generatedLevelsPreview;
  final List<TextEditingController> _previewControllers = [];

  final _types = [
    ('study', '📚', 'Study'),
    ('gym', '💪', 'Fitness'),
    ('work', '💼', 'Work'),
    ('custom', '🎯', 'Custom'),
  ];

  final _loadingMessages = [
    "Analyzing your goal... 🧠",
    "Building level map... 🏗️",
    "Almost ready... ✨",
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
    _aiGoalTitleCtrl.dispose();
    _aiGoalDescCtrl.dispose();
    for (final l in _manualLevels) {
      l.dispose();
    }
    _clearPreviewControllers();
    _loadingTimer?.cancel();
    super.dispose();
  }

  void _clearPreviewControllers() {
    for (final ctrl in _previewControllers) {
      ctrl.dispose();
    }
    _previewControllers.clear();
  }

  Future<void> _pickDeadline() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: const Color(0xFF0A0A0F),
          colorScheme: const ColorScheme.dark(
            primary: AppColors.brand,
            surface: Color(0xFF12121A),
            onSurface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _deadline = picked);
  }

  // Generate with client fallback
  List<Map<String, dynamic>> _generateSmartRoadmap(String title, String description, String type) {
    final lowerTitle = title.toLowerCase();
    final lowerDesc = description.toLowerCase();
    
    List<String> titles;
    String defaultProof = 'quiz';
    
    if (type == 'study' && (lowerTitle.contains('dsa') || lowerTitle.contains('data structure') || lowerDesc.contains('algorithm'))) {
      titles = [
        'Arrays & Slicing',
        'Strings & Pattern Matching',
        'Linked Lists',
        'Stacks & Queues',
        'Trees & Recursion',
        'Graphs & Traversals (DFS/BFS)',
        'Heaps & Priority Queues',
        'Dynamic Programming Foundations',
        'Sorting & Searching Algorithms',
        'Final Project: Optimized System Design'
      ];
      defaultProof = 'quiz';
    } else if (type == 'study') {
      titles = [
        'Foundations of $title',
        'Core Terminology & Concepts',
        'Basic Practical Application',
        'Intermediate Techniques',
        'Deep Dive & Advanced Methods',
        'Common Mistakes & Best Practices',
        'Real-world Case Studies',
        'Final Knowledge Assessment'
      ];
      defaultProof = 'quiz';
    } else if (type == 'gym') {
      titles = [
        'Week 1: Form & Mobility Foundations',
        'Week 2: Base Volume Conditioning',
        'Week 3: Progressive Overload & Intensity',
        'Week 4: Peak Work Capacity',
        'Week 5: Active Recovery & Deload',
        'Week 6: Final Strength & Endurance Test'
      ];
      defaultProof = 'timer';
    } else if (type == 'work') {
      titles = [
        'Milestone 1: Project Alignment & Setup',
        'Milestone 2: Prototype Architecture Design',
        'Milestone 3: Core Database Schema & Entities',
        'Milestone 4: Core API Development & Integration',
        'Milestone 5: Frontend UI Component Scaffold',
        'Milestone 6: API Wiring & Core User Flow',
        'Milestone 7: Test Coverage & Edge Cases',
        'Milestone 8: Live Deployment & Launch'
      ];
      defaultProof = 'code';
    } else {
      titles = [
        'Introduction to $title',
        'Core Principles of the Topic',
        'Hands-on Practical Exercises',
        'Advanced Strategies & Insights',
        'Final Showcase Project'
      ];
      defaultProof = 'code';
    }
    
    return List.generate(titles.length, (index) {
      final num = index + 1;
      return {
        'levelNumber': num,
        'title': titles[index],
        'description': 'Master this level by completing the required validation for ${titles[index]}.',
        'proofType': defaultProof,
        'estimatedMinutes': 45 + (index % 3) * 15,
        'xpReward': 100 + (index % 3) * 50,
      };
    });
  }

  Future<void> _generateAI() async {
    final title = _aiGoalTitleCtrl.text.trim();
    if (title.isEmpty) {
      setState(() => _aiTitleError = 'Goal Title is required');
      return;
    }
    setState(() {
      _aiTitleError = '';
      _isGeneratingAI = true;
      _loadingMsgIdx = 0;
    });

    // Animate loading text
    _loadingTimer = Timer.periodic(const Duration(milliseconds: 1000), (timer) {
      if (mounted && _isGeneratingAI) {
        setState(() {
          _loadingMsgIdx = (_loadingMsgIdx + 1) % _loadingMessages.length;
        });
      }
    });

    try {
      final dio = ref.read(roadmapProvider.notifier).dio;
      final response = await dio.post(
        '/ai/generate-roadmap',
        data: {
          'title': title,
          'description': _aiGoalDescCtrl.text.trim(),
          'type': _selectedType,
        },
      );
      
      final data = response.data;
      List<Map<String, dynamic>> levels = [];
      if (data is Map && data['levels'] is List) {
        levels = List<Map<String, dynamic>>.from(data['levels']);
      } else {
        throw Exception("Invalid levels response");
      }

      setState(() {
        _isGeneratingAI = false;
        _generatedLevelsPreview = levels;
        _clearPreviewControllers();
        for (final lvl in levels) {
          _previewControllers.add(TextEditingController(text: lvl['title']));
        }
      });
    } catch (_) {
      // Fallback client-side template
      await Future.delayed(const Duration(milliseconds: 2500)); // Simulating latency
      final levels = _generateSmartRoadmap(title, _aiGoalDescCtrl.text.trim(), _selectedType);
      
      setState(() {
        _isGeneratingAI = false;
        _generatedLevelsPreview = levels;
        _clearPreviewControllers();
        for (final lvl in levels) {
          _previewControllers.add(TextEditingController(text: lvl['title']));
        }
      });
    } finally {
      _loadingTimer?.cancel();
    }
  }

  Future<void> _saveAI() async {
    if (_generatedLevelsPreview == null) return;
    
    final title = _aiGoalTitleCtrl.text.trim();
    final description = _aiGoalDescCtrl.text.trim();
    
    // Read updated level titles
    final List<Map<String, dynamic>> finalizedLevels = [];
    for (int i = 0; i < _generatedLevelsPreview!.length; i++) {
      final item = Map<String, dynamic>.from(_generatedLevelsPreview![i]);
      item['title'] = _previewControllers[i].text.trim();
      finalizedLevels.add(item);
    }

    final payload = {
      'title': title,
      'description': description.isNotEmpty ? description : 'AI generated roadmap for $title',
      'type': _selectedType,
      'source': 'ai',
      'examMode': false,
      'levels': finalizedLevels,
    };

    final roadmap = await ref.read(roadmapProvider.notifier).createRoadmap(payload);
    if (roadmap != null && mounted) {
      context.go('${AppRoutes.map}/${roadmap.id}');
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save roadmap. Please try again.')),
      );
    }
  }

  Future<void> _createManual() async {
    if (_titleCtrl.text.trim().isEmpty) {
      setState(() => _titleError = 'Title is required');
      return;
    }
    if (_manualLevels.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('At least 1 level is required')),
      );
      return;
    }

    setState(() => _titleError = '');

    // Format levels
    final levelsPayload = _manualLevels.asMap().entries.map((entry) {
      final index = entry.key;
      final lvl = entry.value;
      return {
        'levelNumber': index + 1,
        'title': lvl.controller.text.trim().isNotEmpty
            ? lvl.controller.text.trim()
            : 'Level ${index + 1}',
        'description': 'Master this level by completing the verification.',
        'proofType': lvl.proofType,
        'estimatedMinutes': 45,
        'xpReward': 100,
      };
    }).toList();

    final payload = {
      'title': _titleCtrl.text.trim(),
      'description': _descCtrl.text.trim(),
      'type': _selectedType,
      'source': 'manual',
      'examMode': _examMode,
      if (_deadline != null) 'deadline': _deadline!.toIso8601String(),
      'levels': levelsPayload,
    };

    final roadmap = await ref.read(roadmapProvider.notifier).createRoadmap(payload);
    if (roadmap != null && mounted) {
      context.go('${AppRoutes.map}/${roadmap.id}');
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to create roadmap. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(roadmapProvider).isLoading;

    if (_isGeneratingAI) {
      return Scaffold(
        backgroundColor: const Color(0xFF0A0A0F),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                width: 64, height: 64,
                child: CircularProgressIndicator(
                  color: AppColors.brand,
                  strokeWidth: 4,
                ),
              ),
              const SizedBox(height: 24),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  _loadingMessages[_loadingMsgIdx],
                  key: ValueKey(_loadingMsgIdx),
                  style: GoogleFonts.syne(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_generatedLevelsPreview != null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0A0A0F),
        appBar: AppBar(
          title: Text('Preview Roadmap Map', style: AppTextStyles.h3),
          backgroundColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.close, color: AppColors.textPrimary),
            onPressed: () => setState(() => _generatedLevelsPreview = null),
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.pagePadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Customize your milestone titles below before creating:',
                    style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary)),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    itemCount: _generatedLevelsPreview!.length,
                    itemBuilder: (ctx, index) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF12121A),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF1E1E2E)),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: AppColors.brand.withOpacity(0.2),
                              child: Text(
                                '${index + 1}',
                                style: GoogleFonts.syne(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.brand,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: _previewControllers[index],
                                style: GoogleFonts.inter(fontSize: 14, color: Colors.white),
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                StepUpButton(
                  label: 'Save & Start Roadmap Map 🚀',
                  isLoading: isLoading,
                  onPressed: _saveAI,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
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
          // Manual Tab
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(AppSpacing.pagePadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSpacing.md),
                StepUpInput(
                  label: 'Roadmap Title',
                  hint: 'e.g. Master React in 30 Days',
                  controller: _titleCtrl,
                  errorText: _titleError.isEmpty ? null : _titleError,
                ).animate().fadeIn(delay: 100.ms),
                const SizedBox(height: AppSpacing.base),
                StepUpInput(
                  label: 'Description (optional)',
                  hint: 'What is this roadmap about?',
                  controller: _descCtrl,
                  maxLines: 2,
                ).animate().fadeIn(delay: 150.ms),
                const SizedBox(height: AppSpacing.xl),
                Text('Category', style: AppTextStyles.label).animate().fadeIn(delay: 200.ms),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: _types.map((t) {
                    final (id, emoji, label) = t;
                    final isSelected = _selectedType == id;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedType = id),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: isSelected ? AppColors.brandGradient : null,
                          color: isSelected ? null : const Color(0xFF12121A),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: isSelected ? Colors.transparent : const Color(0xFF1E1E2E),
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
                
                // Add Levels Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Roadmap Milestones', style: AppTextStyles.bodyLarge),
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _manualLevels.add(_ManualLevel(
                            title: 'Level ${_manualLevels.length + 1}',
                            proofType: 'quiz',
                          ));
                        });
                      },
                      icon: const Icon(Icons.add, size: 16, color: AppColors.brand),
                      label: Text(
                        'Add Level',
                        style: GoogleFonts.inter(fontSize: 13, color: AppColors.brand, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ).animate().fadeIn(delay: 250.ms),
                const SizedBox(height: AppSpacing.sm),

                // Drag to reorder list of levels
                if (_manualLevels.isNotEmpty)
                  ReorderableListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _manualLevels.length,
                    itemBuilder: (ctx, index) {
                      final lvl = _manualLevels[index];
                      return Container(
                        key: ValueKey(lvl),
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF12121A),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF1E1E2E)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.drag_indicator, color: AppColors.textMuted, size: 20),
                            const SizedBox(width: 8),
                            CircleAvatar(
                              radius: 12,
                              backgroundColor: AppColors.brand.withOpacity(0.15),
                              child: Text(
                                '${index + 1}',
                                style: GoogleFonts.syne(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.brand),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: lvl.controller,
                                style: GoogleFonts.inter(fontSize: 14, color: Colors.white),
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                  hintText: 'Level title',
                                  hintStyle: TextStyle(color: AppColors.textMuted),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            DropdownButton<String>(
                              value: lvl.proofType,
                              dropdownColor: const Color(0xFF12121A),
                              underline: const SizedBox(),
                              items: const [
                                DropdownMenuItem(value: 'quiz', child: Text('Quiz 📝', style: TextStyle(fontSize: 13))),
                                DropdownMenuItem(value: 'timer', child: Text('Timer ⏱️', style: TextStyle(fontSize: 13))),
                                DropdownMenuItem(value: 'code', child: Text('Code 💻', style: TextStyle(fontSize: 13))),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => lvl.proofType = val);
                                }
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 18),
                              onPressed: () {
                                if (_manualLevels.length > 1) {
                                  setState(() {
                                    lvl.dispose();
                                    _manualLevels.removeAt(index);
                                  });
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('At least 1 level is required')),
                                  );
                                }
                              },
                            )
                          ],
                        ),
                      );
                    },
                    onReorder: (oldIdx, newIdx) {
                      setState(() {
                        if (newIdx > oldIdx) newIdx -= 1;
                        final item = _manualLevels.removeAt(oldIdx);
                        _manualLevels.insert(newIdx, item);
                      });
                    },
                  ).animate().fadeIn(delay: 260.ms),

                const SizedBox(height: AppSpacing.base),
                
                // Exam Mode Switch
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
                    Switch(
                      value: _examMode,
                      onChanged: (val) => setState(() => _examMode = val),
                      activeColor: AppColors.brand,
                    ),
                  ],
                ).animate().fadeIn(delay: 280.ms),
                
                // Deadline Date Picker
                if (_examMode) ...[
                  const SizedBox(height: AppSpacing.md),
                  GestureDetector(
                    onTap: _pickDeadline,
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.base),
                      decoration: BoxDecoration(
                        color: const Color(0xFF12121A),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF1E1E2E)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_outlined, color: AppColors.textSecondary, size: 20),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Deadline', style: AppTextStyles.label),
                                Text(
                                  _deadline != null
                                      ? '${_deadline!.day}/${_deadline!.month}/${_deadline!.year}'
                                      : 'Choose a target date...',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                      color: _deadline != null
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
                  ).animate().fadeIn(delay: 300.ms),
                ],

                const SizedBox(height: AppSpacing.xxxl),
                StepUpButton(
                  label: 'Create Roadmap Map 🚀',
                  isLoading: isLoading,
                  onPressed: _createManual,
                ).animate().fadeIn(delay: 350.ms),
              ],
            ),
          ),

          // AI Generate Tab
          SingleChildScrollView(
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
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.brand.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Text('✨', style: TextStyle(fontSize: 28)),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(
                          'Describe your goal, timeline, and current level. Our AI will automatically construct a customized learning path.',
                          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                StepUpInput(
                  label: 'Goal Title',
                  hint: 'e.g. Learn Python for Data Science',
                  controller: _aiGoalTitleCtrl,
                  errorText: _aiTitleError.isEmpty ? null : _aiTitleError,
                ),
                const SizedBox(height: AppSpacing.base),
                StepUpInput(
                  label: 'Describe your goal, timeline, and current level',
                  hint: 'e.g. I want to learn DSA in 30 days. I know basic programming.',
                  controller: _aiGoalDescCtrl,
                  maxLines: 4,
                ),
                const SizedBox(height: AppSpacing.xl),
                Text('Category', style: AppTextStyles.label),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: _types.map((t) {
                    final (id, emoji, label) = t;
                    final isSelected = _selectedType == id;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedType = id),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: isSelected ? AppColors.brandGradient : null,
                          color: isSelected ? null : const Color(0xFF12121A),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: isSelected ? Colors.transparent : const Color(0xFF1E1E2E),
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
                ),
                const SizedBox(height: AppSpacing.xxxl),
                StepUpButton(
                  label: 'Generate with AI ✨',
                  isLoading: isLoading,
                  onPressed: _generateAI,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
