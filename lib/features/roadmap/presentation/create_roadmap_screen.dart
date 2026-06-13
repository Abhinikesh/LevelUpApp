import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/router/app_router.dart';
import '../../../core/storage/token_storage.dart';
import '../../../shared/providers/roadmap_provider.dart';
import '../../../shared/widgets/stepup_button.dart';
import '../../../shared/widgets/stepup_input.dart';

// ─── Proof type cycle order ──────────────────────────────────────
const _kProofCycleOrder = ['quiz', 'photo', 'code', 'timer', 'screenshot'];

String _nextProofType(String current) {
  final idx = _kProofCycleOrder.indexOf(current);
  return _kProofCycleOrder[(idx + 1) % _kProofCycleOrder.length];
}

IconData _proofIcon(String pt) {
  switch (pt) {
    case 'quiz': return Icons.quiz_outlined;
    case 'photo': return Icons.camera_alt_outlined;
    case 'code': return Icons.code_rounded;
    case 'timer': return Icons.timer_outlined;
    case 'screenshot': return Icons.screenshot_monitor_outlined;
    default: return Icons.edit_outlined;
  }
}

Color _proofColor(String pt) {
  switch (pt) {
    case 'quiz': return const Color(0xFF7B6EF6);
    case 'photo': return const Color(0xFF4A9EFF);
    case 'code': return const Color(0xFF2DD4BF);
    case 'timer': return const Color(0xFFFFB156);
    case 'screenshot': return const Color(0xFFFF6B9D);
    default: return const Color(0xFF9898B8);
  }
}

// ─── ProofTypeCycleChip ──────────────────────────────────────────
class _ProofTypeCycleChip extends StatelessWidget {
  final String proofType;
  final VoidCallback onCycle;

  const _ProofTypeCycleChip({required this.proofType, required this.onCycle});

  @override
  Widget build(BuildContext context) {
    final color = _proofColor(proofType);
    final icon = _proofIcon(proofType);
    return GestureDetector(
      onTap: onCycle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.6), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 5),
            Text(
              proofType,
              style: GoogleFonts.spaceMono(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.swap_horiz_rounded, size: 12, color: color.withValues(alpha: 0.7)),
          ],
        ),
      ),
    );
  }
}

// ─── Manual Sub-Level Data ───────────────────────────────────────
class _ManualSubLevel {
  final TextEditingController controller;
  String proofType;

  _ManualSubLevel({required String title, String initialProofType = 'quiz'})
      : controller = TextEditingController(text: title),
        proofType = initialProofType;

  void dispose() => controller.dispose();
}

// ─── Manual Level Data ───────────────────────────────────────────
class _ManualLevel {
  final TextEditingController controller;
  String proofType;
  final List<_ManualSubLevel> subLevels;
  bool isExpanded;

  _ManualLevel({
    required String title,
    this.proofType = 'quiz',
  })  : controller = TextEditingController(text: title),
        isExpanded = false,
        subLevels = [];

  void dispose() {
    controller.dispose();
    for (final s in subLevels) {
      s.dispose();
    }
  }
}

// ─── Main Screen ─────────────────────────────────────────────────
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

  // ─── Wizard (AI Generate Tab) ─────────────────────────────────
  final _wizardPageCtrl = PageController();
  int _wizardStep = 0;
  String? _wizardSkill; // python|dsa|mern|flutter|gym|aiml|work|custom
  final _customSkillCtrl = TextEditingController();
  int _wizardDays = 30;
  bool _useCustomDays = false;
  final _customDaysCtrl = TextEditingController();
  String _wizardTime = '1h'; // 30min|1h|2h|3h+
  String _wizardLevel = 'beginner';
  String _wizardStyle = 'mixed';

  // ─── Loading ─────────────────────────────────────────────
  bool _isGeneratingAI = false;
  bool _isCreating = false;
  int _loadingMsgIdx = 0;
  Timer? _loadingTimer;

  final _loadingMessages = [
    'Sending to Grok AI... 🧠',
    'Building your roadmap... 🗺️',
    'Crafting milestones... 🏆',
    'Almost ready! ✨',
  ];

  // ─── Manual Tab State ────────────────────────────────────
  String _selectedType = 'study';
  String _mapStyle = 'simple'; // 'simple' or 'sublevels'
  bool _examMode = false;
  DateTime? _deadline;
  String _titleError = '';

  final _types = [
    ('study', '\ud83d\udcda', 'Study'),
    ('gym', '\ud83d\udcaa', 'Fitness'),
    ('work', '\ud83d\udcbc', 'Work'),
    ('custom', '\ud83c\udfaf', 'Custom'),
  ];

  final List<_ManualLevel> _manualLevels = [
    _ManualLevel(title: 'Level 1: Introduction', proofType: 'quiz'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Trigger rebuild when custom text changes (to enable/disable Next button)
    _customSkillCtrl.addListener(() => setState(() {}));
    _customDaysCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _wizardPageCtrl.dispose();
    _customSkillCtrl.dispose();
    _customDaysCtrl.dispose();
    for (final l in _manualLevels) {
      l.dispose();
    }
    _loadingTimer?.cancel();
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

  // ── Generate with full templates + OpenAI fallback ──────────
  List<Map<String, dynamic>> _generateSmartRoadmap(
      String title, String description, String type) {
    final lowerTitle = title.toLowerCase();
    final lowerDesc = description.toLowerCase();

    List<Map<String, dynamic>> levels;

    // ── DSA / Data Structures ──
    if (type == 'study' &&
        (lowerTitle.contains('dsa') ||
            lowerTitle.contains('data struct') ||
            lowerTitle.contains('algorithm') ||
            lowerDesc.contains('algorithm') ||
            lowerDesc.contains('leetcode'))) {
      levels = [
        {'levelNumber': 1, 'title': 'Arrays & Slicing', 'description': 'Master 1-D and 2-D arrays, index tricks, prefix sums, and the two-pointer pattern.', 'proofType': 'quiz', 'estimatedMinutes': 45, 'xpReward': 100},
        {'levelNumber': 2, 'title': 'Strings & Pattern Matching', 'description': 'Sliding window, anagram checks, palindrome detection, and KMP basics.', 'proofType': 'quiz', 'estimatedMinutes': 45, 'xpReward': 100},
        {'levelNumber': 3, 'title': 'Linked Lists', 'description': 'Singly/doubly linked lists, fast-slow pointers, cycle detection, reversal.', 'proofType': 'quiz', 'estimatedMinutes': 50, 'xpReward': 100},
        {'levelNumber': 4, 'title': 'Stacks & Queues', 'description': 'Monotonic stacks, queue using stacks, sliding window maximum.', 'proofType': 'quiz', 'estimatedMinutes': 45, 'xpReward': 100},
        {'levelNumber': 5, 'title': 'Binary Search & Variants', 'description': 'Classic binary search, search rotated array, find peak element, search range.', 'proofType': 'quiz', 'estimatedMinutes': 50, 'xpReward': 150},
        {'levelNumber': 6, 'title': 'Trees & Recursion', 'description': 'BST operations, DFS traversals, LCA, height, diameter, and path sums.', 'proofType': 'quiz', 'estimatedMinutes': 60, 'xpReward': 150},
        {'levelNumber': 7, 'title': 'Graphs — BFS & DFS', 'description': 'Adjacency list/matrix, connected components, topological sort, cycle detection.', 'proofType': 'quiz', 'estimatedMinutes': 60, 'xpReward': 150},
        {'levelNumber': 8, 'title': 'Heaps & Priority Queues', 'description': 'Min/max heap ops, K largest elements, merge K sorted lists, task scheduler.', 'proofType': 'quiz', 'estimatedMinutes': 50, 'xpReward': 150},
        {'levelNumber': 9, 'title': 'Dynamic Programming I — 1D', 'description': 'Fibonacci, climbing stairs, house robber, coin change, longest increasing subsequence.', 'proofType': 'quiz', 'estimatedMinutes': 70, 'xpReward': 200},
        {'levelNumber': 10, 'title': 'Dynamic Programming II — 2D', 'description': 'Grid DP, edit distance, knapsack 0/1, partition equal subset sum.', 'proofType': 'quiz', 'estimatedMinutes': 75, 'xpReward': 200},
        {'levelNumber': 11, 'title': 'Sorting Deep Dive', 'description': 'Merge sort, quick sort, counting sort, custom comparators, sort colors.', 'proofType': 'quiz', 'estimatedMinutes': 45, 'xpReward': 100},
        {'levelNumber': 12, 'title': 'Final Challenge: Mock Interview', 'description': 'Time-boxed set of 5 mixed-difficulty problems. Prove mastery under pressure.', 'proofType': 'code', 'estimatedMinutes': 90, 'xpReward': 300},
      ];
    }
    // ── Web / React ──
    else if (type == 'study' &&
        (lowerTitle.contains('react') ||
            lowerTitle.contains('web') ||
            lowerTitle.contains('frontend') ||
            lowerTitle.contains('next') ||
            lowerDesc.contains('react') ||
            lowerDesc.contains('javascript'))) {
      levels = [
        {'levelNumber': 1, 'title': 'HTML & Semantic Structure', 'description': 'Forms, accessibility, semantic HTML5 elements, and valid markup.', 'proofType': 'quiz', 'estimatedMinutes': 40, 'xpReward': 100},
        {'levelNumber': 2, 'title': 'CSS & Layouts', 'description': 'Flexbox, CSS Grid, responsive design, custom properties, animations.', 'proofType': 'quiz', 'estimatedMinutes': 50, 'xpReward': 100},
        {'levelNumber': 3, 'title': 'JavaScript Essentials', 'description': 'ES6+, closures, promises, async/await, event loop, DOM manipulation.', 'proofType': 'quiz', 'estimatedMinutes': 60, 'xpReward': 150},
        {'levelNumber': 4, 'title': 'React Foundations', 'description': 'JSX, components, props, state, lifecycle with hooks (useState, useEffect).', 'proofType': 'code', 'estimatedMinutes': 60, 'xpReward': 150},
        {'levelNumber': 5, 'title': 'State Management', 'description': 'Context API, useReducer, Zustand/Redux basics — when to use which.', 'proofType': 'code', 'estimatedMinutes': 60, 'xpReward': 150},
        {'levelNumber': 6, 'title': 'API Integration & Data Fetching', 'description': 'fetch, axios, React Query — loading states, error boundaries, caching.', 'proofType': 'code', 'estimatedMinutes': 60, 'xpReward': 150},
        {'levelNumber': 7, 'title': 'Performance & Optimization', 'description': 'useMemo, useCallback, code splitting, lazy loading, Core Web Vitals.', 'proofType': 'quiz', 'estimatedMinutes': 45, 'xpReward': 200},
        {'levelNumber': 8, 'title': 'Final Project: Full-stack Feature', 'description': 'Build and ship a complete user-facing feature end-to-end. Deploy on Vercel.', 'proofType': 'code', 'estimatedMinutes': 90, 'xpReward': 300},
      ];
    }
    // ── Python ──
    else if (type == 'study' &&
        (lowerTitle.contains('python') ||
            lowerDesc.contains('python') ||
            lowerTitle.contains('data science') ||
            lowerTitle.contains('machine learn'))) {
      levels = [
        {'levelNumber': 1, 'title': 'Python Fundamentals', 'description': 'Variables, data types, control flow, functions, list comprehensions, f-strings.', 'proofType': 'quiz', 'estimatedMinutes': 40, 'xpReward': 100},
        {'levelNumber': 2, 'title': 'OOP & Modules', 'description': 'Classes, inheritance, dunder methods, modules, packages, and virtual environments.', 'proofType': 'quiz', 'estimatedMinutes': 50, 'xpReward': 100},
        {'levelNumber': 3, 'title': 'Data Structures in Python', 'description': 'lists, dicts, sets, tuples, collections module — time complexity of each.', 'proofType': 'quiz', 'estimatedMinutes': 45, 'xpReward': 100},
        {'levelNumber': 4, 'title': 'File I/O & APIs', 'description': 'Reading/writing files, JSON, CSV, requests library, REST API calls.', 'proofType': 'code', 'estimatedMinutes': 45, 'xpReward': 150},
        {'levelNumber': 5, 'title': 'NumPy & Pandas', 'description': 'Array ops, DataFrame manipulation, groupby, merge, vectorization.', 'proofType': 'code', 'estimatedMinutes': 60, 'xpReward': 150},
        {'levelNumber': 6, 'title': 'Data Visualization', 'description': 'Matplotlib, Seaborn — histograms, scatter plots, heatmaps, dashboards.', 'proofType': 'code', 'estimatedMinutes': 50, 'xpReward': 150},
        {'levelNumber': 7, 'title': 'Machine Learning Basics', 'description': 'Scikit-learn — train/test split, linear regression, classification, evaluation metrics.', 'proofType': 'quiz', 'estimatedMinutes': 70, 'xpReward': 200},
        {'levelNumber': 8, 'title': 'Final Project: End-to-end ML Pipeline', 'description': 'Collect data, preprocess, train a model, evaluate, and present findings.', 'proofType': 'code', 'estimatedMinutes': 90, 'xpReward': 300},
      ];
    }
    // ── Gym / Fitness ──
    else if (type == 'gym') {
      levels = [
        {'levelNumber': 1, 'title': 'Week 1: Form & Mobility Foundations', 'description': 'Learn perfect form for squat, deadlift, bench, and overhead press. Focus on range of motion.', 'proofType': 'timer', 'estimatedMinutes': 50, 'xpReward': 100},
        {'levelNumber': 2, 'title': 'Week 2: Base Volume Conditioning', 'description': 'Full-body 3×10 protocol. Build base volume tolerance. Active recovery on rest days.', 'proofType': 'timer', 'estimatedMinutes': 55, 'xpReward': 100},
        {'levelNumber': 3, 'title': 'Week 3: Progressive Overload Introduction', 'description': 'Add 5% load to each compound lift. Track every set and rep. Introduce supersets.', 'proofType': 'timer', 'estimatedMinutes': 60, 'xpReward': 150},
        {'levelNumber': 4, 'title': 'Week 4: Peak Work Capacity', 'description': 'High-volume push/pull/legs split. Prioritize mind-muscle connection.', 'proofType': 'timer', 'estimatedMinutes': 65, 'xpReward': 150},
        {'levelNumber': 5, 'title': 'Week 5: Active Recovery & Deload', 'description': 'Cut volume 40%. Focus on mobility work, sleep, and nutrition. Let muscles recover.', 'proofType': 'timer', 'estimatedMinutes': 40, 'xpReward': 100},
        {'levelNumber': 6, 'title': 'Week 6: Final Strength & Endurance Test', 'description': '1-rep max attempt on squats/bench/deadlift. Timed 2-mile run. Document transformation.', 'proofType': 'timer', 'estimatedMinutes': 75, 'xpReward': 300},
      ];
    }
    // ── Work / Career ──
    else if (type == 'work') {
      levels = [
        {'levelNumber': 1, 'title': 'Milestone 1: Project Alignment & Discovery', 'description': 'Define success metrics, stakeholders, and constraints. Write a 1-pager PRD.', 'proofType': 'code', 'estimatedMinutes': 60, 'xpReward': 100},
        {'levelNumber': 2, 'title': 'Milestone 2: Architecture & Tech Stack', 'description': 'Choose stack, draw system diagram, evaluate trade-offs. Write ADRs.', 'proofType': 'code', 'estimatedMinutes': 60, 'xpReward': 100},
        {'levelNumber': 3, 'title': 'Milestone 3: Database Schema & Models', 'description': 'Design ERD, write migrations, seed data. Validate relationships and indexes.', 'proofType': 'code', 'estimatedMinutes': 60, 'xpReward': 150},
        {'levelNumber': 4, 'title': 'Milestone 4: Core API Development', 'description': 'Implement CRUD endpoints, auth middleware, input validation, error handling.', 'proofType': 'code', 'estimatedMinutes': 90, 'xpReward': 200},
        {'levelNumber': 5, 'title': 'Milestone 5: Frontend UI Scaffold', 'description': 'Build component library, routing, global state setup, design tokens.', 'proofType': 'code', 'estimatedMinutes': 90, 'xpReward': 200},
        {'levelNumber': 6, 'title': 'Milestone 6: API Wiring & Core User Flows', 'description': 'Connect frontend to backend. Implement the 3 primary user journeys end-to-end.', 'proofType': 'code', 'estimatedMinutes': 90, 'xpReward': 200},
        {'levelNumber': 7, 'title': 'Milestone 7: Tests & Edge Cases', 'description': 'Unit tests, integration tests, error boundary coverage. Achieve 80%+ coverage.', 'proofType': 'code', 'estimatedMinutes': 75, 'xpReward': 150},
        {'levelNumber': 8, 'title': 'Milestone 8: Deployment & Launch', 'description': 'CI/CD pipeline, production deploy, monitoring setup. Write launch announcement.', 'proofType': 'code', 'estimatedMinutes': 90, 'xpReward': 300},
      ];
    }
    // ── Custom ──
    else if (type == 'custom') {
      levels = [
        {'levelNumber': 1, 'title': 'Introduction to $title', 'description': 'Lay the groundwork. Understand the core purpose, tools needed, and your starting point.', 'proofType': 'quiz', 'estimatedMinutes': 30, 'xpReward': 100},
        {'levelNumber': 2, 'title': 'Core Concepts & Principles', 'description': 'Deep-dive into the foundational theory behind $title.', 'proofType': 'quiz', 'estimatedMinutes': 45, 'xpReward': 100},
        {'levelNumber': 3, 'title': 'Hands-on Practice', 'description': 'Apply what you have learned in a real, low-stakes environment.', 'proofType': 'code', 'estimatedMinutes': 60, 'xpReward': 150},
        {'levelNumber': 4, 'title': 'Advanced Strategies', 'description': 'Level up with nuanced techniques and edge cases for $title.', 'proofType': 'quiz', 'estimatedMinutes': 60, 'xpReward': 200},
        {'levelNumber': 5, 'title': 'Final Showcase Project', 'description': 'Demonstrate your mastery through a polished deliverable.', 'proofType': 'code', 'estimatedMinutes': 90, 'xpReward': 300},
      ];
    }
    // ── Generic Study fallback ──
    else {
      levels = [
        {'levelNumber': 1, 'title': 'Foundations of $title', 'description': 'Survey the landscape — key terms, history, and why it matters.', 'proofType': 'quiz', 'estimatedMinutes': 40, 'xpReward': 100},
        {'levelNumber': 2, 'title': 'Core Terminology & Concepts', 'description': 'Build your mental model with the 20% of ideas that explain 80% of the domain.', 'proofType': 'quiz', 'estimatedMinutes': 45, 'xpReward': 100},
        {'levelNumber': 3, 'title': 'Basic Practical Application', 'description': 'Transfer knowledge into action — guided exercises with feedback.', 'proofType': 'code', 'estimatedMinutes': 50, 'xpReward': 100},
        {'levelNumber': 4, 'title': 'Intermediate Techniques', 'description': 'Tackle more complex scenarios that require combining ideas from earlier levels.', 'proofType': 'quiz', 'estimatedMinutes': 55, 'xpReward': 150},
        {'levelNumber': 5, 'title': 'Deep Dive & Advanced Methods', 'description': 'Explore the expert-level nuances that separate professionals from beginners.', 'proofType': 'quiz', 'estimatedMinutes': 60, 'xpReward': 200},
        {'levelNumber': 6, 'title': 'Common Mistakes & Best Practices', 'description': 'Study the most frequent failure modes and how to avoid them.', 'proofType': 'quiz', 'estimatedMinutes': 40, 'xpReward': 150},
        {'levelNumber': 7, 'title': 'Real-world Case Studies', 'description': 'Analyse 3 real examples of $title applied at scale. Extract lessons.', 'proofType': 'quiz', 'estimatedMinutes': 50, 'xpReward': 150},
        {'levelNumber': 8, 'title': 'Final Knowledge Assessment', 'description': 'Comprehensive quiz + short written answer. Prove you own this topic.', 'proofType': 'quiz', 'estimatedMinutes': 45, 'xpReward': 200},
      ];
    }

    return levels;
  }

  // ─── Wizard state helpers ────────────────────────────────────
  String _wizardSkillLabel() {
    const labels = {
      'python': 'Python Programming',
      'dsa': 'Data Structures & Algorithms',
      'mern': 'MERN Stack',
      'flutter': 'Flutter Development',
      'gym': 'Gym & Fitness',
      'aiml': 'AI & Machine Learning',
      'work': 'Work Project',
    };
    if (_wizardSkill == 'custom') {
      return _customSkillCtrl.text.trim().isNotEmpty
          ? _customSkillCtrl.text.trim()
          : 'Custom Goal';
    }
    return labels[_wizardSkill] ?? 'My Goal';
  }

  String _buildUserInput() {
    const timeLabels = {
      '30min': '30 minutes',
      '1h': '1 hour',
      '2h': '2 hours',
      '3h+': '3+ hours',
    };
    const levelLabels = {
      'beginner': 'a complete beginner',
      'some': 'someone with some basic knowledge',
      'intermediate': 'an intermediate level learner',
      'advanced': 'an advanced level learner',
    };
    const styleLabels = {
      'project': 'project-based, hands-on learning',
      'theory': 'theory-first, then practice',
      'mixed': 'a balanced mix of theory and practice',
      'fasttrack': 'fast-track intensive, skip basics and go deep',
    };
    final days = _useCustomDays
        ? (int.tryParse(_customDaysCtrl.text.trim()) ?? _wizardDays)
        : _wizardDays;
    final skill = _wizardSkillLabel();
    final time = timeLabels[_wizardTime] ?? '1 hour';
    final level = levelLabels[_wizardLevel] ?? 'a beginner';
    final style = styleLabels[_wizardStyle] ?? 'a mixed approach';
    return 'I want to master $skill in $days days. '
        'I can dedicate $time per day. '
        'I am $level. '
        'I prefer $style. '
        'Create a detailed, practical roadmap with specific milestones.';
  }

  String _mapSkillToType() {
    if (_wizardSkill == 'gym') return 'gym';
    if (_wizardSkill == 'work') return 'work';
    return 'study';
  }

  // ─── AI Generation ─────────────────────────────────────────
  Future<void> _runAIGeneration() async {
    setState(() {
      _isGeneratingAI = true;
      _loadingMsgIdx = 0;
    });
    _loadingTimer = Timer.periodic(const Duration(milliseconds: 1500), (t) {
      if (mounted && _isGeneratingAI) {
        setState(() => _loadingMsgIdx = (_loadingMsgIdx + 1) % _loadingMessages.length);
      }
    });
    try {
      final userInput = _buildUserInput();
      final type = _mapSkillToType();
      final token = await TokenStorage.getToken();

      final aoDio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 90),
      ));
      final response = await aoDio.post(
        '${ApiConstants.baseUrl}${ApiConstants.generateRoadmap}',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
        data: {'userInput': userInput, 'type': type},
      );
      if (!mounted) return;
      final data = response.data as Map<String, dynamic>;
      if (data['success'] == true) {
        final roadmapMap = data['roadmap'] as Map<String, dynamic>;
        final roadmapId = roadmapMap['_id'] as String;
        _loadingTimer?.cancel();
        setState(() => _isGeneratingAI = false);
        context.go('${AppRoutes.map}/$roadmapId');
        return;
      }
      throw Exception(data['message'] ?? 'Generation failed');
    } catch (_) {
      // Fallback: local template + createRoadmap
      await _fallbackLocalGenerate();
    } finally {
      _loadingTimer?.cancel();
      if (mounted) setState(() => _isGeneratingAI = false);
    }
  }

  Future<void> _fallbackLocalGenerate() async {
    if (!mounted) return;
    setState(() => _isCreating = true);
    final type = _mapSkillToType();
    final days = _useCustomDays
        ? (int.tryParse(_customDaysCtrl.text.trim()) ?? _wizardDays)
        : _wizardDays;
    final levels = _generateSmartRoadmap(_wizardSkillLabel(), '', type);
    final payload = {
      'title': _wizardSkillLabel(),
      'description': 'AI-generated ${_wizardSkillLabel()} roadmap — $days day plan',
      'type': type,
      'source': 'ai',
      'mapStyle': 'simple',
      'examMode': false,
      'levels': levels,
    };
    final roadmap = await ref.read(roadmapProvider.notifier).createRoadmap(payload);
    if (!mounted) return;
    setState(() => _isCreating = false);
    if (roadmap != null) {
      context.go('${AppRoutes.map}/${roadmap.id}');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to generate roadmap. Please try again.')),
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

    setState(() {
      _titleError = '';
      _isCreating = true;
    });

    // Build levels payload (with subLevels if mapStyle == 'sublevels')
    final levelsPayload = _manualLevels.asMap().entries.map((entry) {
      final index = entry.key;
      final lvl = entry.value;
      final baseLevel = {
        'levelNumber': index + 1,
        'title': lvl.controller.text.trim().isNotEmpty
            ? lvl.controller.text.trim()
            : 'Level ${index + 1}',
        'description': 'Master this level by completing the verification.',
        'proofType': lvl.proofType,
        'estimatedMinutes': 45,
        'xpReward': 100,
      };
      if (_mapStyle == 'sublevels' && lvl.subLevels.isNotEmpty) {
        baseLevel['subLevels'] = lvl.subLevels.asMap().entries.map((se) {
          return {
            'id': 'sub-${se.key}',
            'title': se.value.controller.text.trim().isNotEmpty
                ? se.value.controller.text.trim()
                : 'Sub-topic ${se.key + 1}',
            'description': '',
            'proofType': se.value.proofType,
            'orderIndex': se.key,
            'isCompleted': false,
          };
        }).toList();
      }
      return baseLevel;
    }).toList();

    final payload = {
      'title': _titleCtrl.text.trim(),
      'description': _descCtrl.text.trim(),
      'type': _selectedType,
      'source': 'manual',
      'mapStyle': _mapStyle,
      'examMode': _examMode,
      if (_deadline != null) 'deadline': _deadline!.toIso8601String(),
      'levels': levelsPayload,
    };

    final roadmap =
        await ref.read(roadmapProvider.notifier).createRoadmap(payload);
    if (!mounted) return;
    if (roadmap != null) {
      context.go('${AppRoutes.map}/${roadmap.id}');
    } else {
      setState(() => _isCreating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Failed to create roadmap. Please try again.')),
      );
    }
  }

  // ─── Map Style Selector ─────────────────────────────────────────
  Widget _buildMapStyleSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Map Style', style: AppTextStyles.label),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _MapStyleCard(
              title: 'Simple Levels',
              description: 'One level at a time, step by step',
              icon: _LinearChainIcon(color: _mapStyle == 'simple' ? AppColors.brand : AppColors.textMuted),
              isSelected: _mapStyle == 'simple',
              onTap: () => setState(() => _mapStyle = 'simple'),
            )),
            const SizedBox(width: 10),
            Expanded(child: _MapStyleCard(
              title: 'Topics & Sub-topics',
              description: 'Main topics with detailed sub-tasks',
              example: 'Arrays → Two Pointer, Sliding Window',
              icon: _BranchTreeIcon(color: _mapStyle == 'sublevels' ? AppColors.brand : AppColors.textMuted),
              isSelected: _mapStyle == 'sublevels',
              onTap: () => setState(() => _mapStyle = 'sublevels'),
            )),
          ],
        ),
      ],
    );
  }

  // ─── Manual Level List ──────────────────────────────────────────
  Widget _buildManualLevelList() {
    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _manualLevels.length,
      itemBuilder: (ctx, index) {
        final lvl = _manualLevels[index];
        return _ManualLevelTile(
          key: ValueKey(lvl),
          lvl: lvl,
          index: index,
          showSubLevels: _mapStyle == 'sublevels',
          onDelete: () {
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
          onProofTypeCycle: () => setState(() {
            lvl.proofType = _nextProofType(lvl.proofType);
          }),
          onToggleExpanded: () => setState(() {
            lvl.isExpanded = !lvl.isExpanded;
          }),
          onAddSubLevel: () => setState(() {
            lvl.subLevels.add(_ManualSubLevel(title: 'Sub-topic ${lvl.subLevels.length + 1}'));
          }),
          onDeleteSubLevel: (si) => setState(() {
            lvl.subLevels[si].dispose();
            lvl.subLevels.removeAt(si);
          }),
          onSubProofCycle: (si) => setState(() {
            lvl.subLevels[si].proofType = _nextProofType(lvl.subLevels[si].proofType);
          }),
          onRebuild: () => setState(() {}),
        );
      },
      onReorder: (oldIdx, newIdx) {
        setState(() {
          if (newIdx > oldIdx) newIdx -= 1;
          final item = _manualLevels.removeAt(oldIdx);
          _manualLevels.insert(newIdx, item);
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final roadmapState = ref.watch(roadmapProvider);
    if (roadmapState.error != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_isCreating) {
          ref.read(roadmapProvider.notifier).clearError();
        }
      });
    }

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
          // ── Manual Tab ─────────────────────────────────────────
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.pagePadding,
              AppSpacing.pagePadding,
              AppSpacing.pagePadding,
              140,
            ),
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

                // Category
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
                            BoxShadow(color: AppColors.brand.withValues(alpha: 0.3), blurRadius: 8),
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

                // Map Style Selector
                _buildMapStyleSelector().animate().fadeIn(delay: 220.ms),
                const SizedBox(height: AppSpacing.xl),

                // Milestones header
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

                if (_manualLevels.isNotEmpty)
                  _buildManualLevelList().animate().fadeIn(delay: 260.ms),

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
                      activeThumbColor: AppColors.brand,
                    ),
                  ],
                ).animate().fadeIn(delay: 280.ms),

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
                          const Icon(Icons.arrow_forward_ios,
                              size: 14, color: AppColors.textMuted),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(delay: 300.ms),
                ],

                const SizedBox(height: AppSpacing.xxxl),
                StepUpButton(
                  label: _isCreating ? 'Creating Roadmap...' : 'Create Roadmap 🚀',
                  isLoading: _isCreating,
                  onPressed: _isCreating ? null : _createManual,
                ).animate().fadeIn(delay: 350.ms),
              ],
            ),
          ),

          // ── AI Generate Tab (5-step Wizard) ──────────────────────
          _buildWizardTab(),
        ],
      ),
    );
  }

  // ─── Wizard Build Methods ───────────────────────────────────────
  Widget _buildWizardTab() {
    return Column(
      children: [
        _buildWizardHeader(),
        Expanded(
          child: PageView(
            controller: _wizardPageCtrl,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildStep1Skill(),
              _buildStep2Duration(),
              _buildStep3Time(),
              _buildStep4Level(),
              _buildStep5Style(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWizardHeader() {
    const titles = ['Choose Goal', 'Duration', 'Daily Time', 'Your Level', 'Learning Style'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Step ${_wizardStep + 1} of 5',
                  style: GoogleFonts.spaceMono(
                      fontSize: 11, fontWeight: FontWeight.w700,
                      color: AppColors.brand, letterSpacing: 0.5)),
              Text(titles[_wizardStep.clamp(0, 4)],
                  style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (_wizardStep + 1) / 5,
              backgroundColor: const Color(0xFF1E1E2E),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.brand),
              minHeight: 3,
            ),
          ),
        ],
      ),
    );
  }

  void _wizardNext() {
    if (_wizardStep >= 4) return;
    final next = _wizardStep + 1;
    setState(() => _wizardStep = next);
    _wizardPageCtrl.animateToPage(next,
        duration: const Duration(milliseconds: 350), curve: Curves.easeInOutCubic);
  }

  void _wizardPrev() {
    if (_wizardStep <= 0) return;
    final prev = _wizardStep - 1;
    setState(() => _wizardStep = prev);
    _wizardPageCtrl.animateToPage(prev,
        duration: const Duration(milliseconds: 350), curve: Curves.easeInOutCubic);
  }

  // ── Step 1: Skill ────────────────────────────────────────────────
  Widget _buildStep1Skill() {
    final skills = [
      ('python', '🐍', 'Python'),
      ('dsa', '📊', 'DSA'),
      ('mern', '🌐', 'MERN Stack'),
      ('flutter', '📱', 'Flutter'),
      ('gym', '💪', 'Gym / Fitness'),
      ('aiml', '🤖', 'AI / ML'),
      ('work', '💼', 'Custom Work'),
      ('custom', '✏️', 'Custom'),
    ];
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 140),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('What do you want\nto learn?',
              style: GoogleFonts.syne(fontSize: 24, fontWeight: FontWeight.w800,
                  color: Colors.white, height: 1.2))
              .animate().fadeIn(duration: 300.ms).slideY(begin: 0.08),
          const SizedBox(height: 4),
          Text('Select a skill or goal to get started',
              style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary))
              .animate().fadeIn(delay: 80.ms),
          const SizedBox(height: 24),
          GridView.count(
            crossAxisCount: 2, shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 2.6,
            children: skills.map((s) {
              final id = s.$1; final emoji = s.$2; final label = s.$3;
              final isSelected = _wizardSkill == id;
              return GestureDetector(
                onTap: () {
                  setState(() => _wizardSkill = id);
                  HapticFeedback.lightImpact();
                  if (id != 'custom') {
                    Future.delayed(const Duration(milliseconds: 220), () {
                      if (mounted && _wizardSkill == id) _wizardNext();
                    });
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    gradient: isSelected ? AppColors.brandGradient : null,
                    color: isSelected ? null : const Color(0xFF12121A),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: isSelected ? Colors.transparent : const Color(0xFF1E1E2E)),
                    boxShadow: isSelected
                        ? [BoxShadow(color: AppColors.brand.withValues(alpha: 0.35), blurRadius: 12)]
                        : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(emoji, style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: 8),
                      Text(label,
                          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700,
                              color: isSelected ? Colors.white : AppColors.textSecondary)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ).animate().fadeIn(delay: 120.ms),
          if (_wizardSkill == 'custom') ...[
            const SizedBox(height: 20),
            StepUpInput(
              label: 'Describe your goal',
              hint: 'e.g. Learn Rust, Build a startup, Master piano...',
              controller: _customSkillCtrl,
              maxLines: 2,
            ).animate().fadeIn(),
            const SizedBox(height: 16),
            StepUpButton(
              label: 'Next →',
              onPressed: _customSkillCtrl.text.trim().isNotEmpty ? _wizardNext : null,
            ),
          ],
        ],
      ),
    );
  }

  // ── Step 2: Duration ─────────────────────────────────────────────
  Widget _buildStep2Duration() {
    const options = [7, 15, 30, 60, 90, 180];
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 140),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBackRow(),
          const SizedBox(height: 16),
          Text('How many days?',
              style: GoogleFonts.syne(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white))
              .animate().fadeIn(duration: 300.ms),
          const SizedBox(height: 4),
          Text('Choose your roadmap duration',
              style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary))
              .animate().fadeIn(delay: 80.ms),
          const SizedBox(height: 24),
          Wrap(
            spacing: 10, runSpacing: 10,
            children: [
              ...options.map((d) {
                final isSelected = !_useCustomDays && _wizardDays == d;
                return GestureDetector(
                  onTap: () {
                    setState(() { _wizardDays = d; _useCustomDays = false; });
                    HapticFeedback.lightImpact();
                    Future.delayed(const Duration(milliseconds: 220), () {
                      if (mounted) _wizardNext();
                    });
                  },
                  child: _WizardChip(label: '$d Days', isSelected: isSelected),
                );
              }),
              GestureDetector(
                onTap: () => setState(() => _useCustomDays = !_useCustomDays),
                child: _WizardChip(label: 'Custom', isSelected: _useCustomDays,
                    icon: Icons.edit_outlined),
              ),
            ],
          ).animate().fadeIn(delay: 120.ms),
          if (_useCustomDays) ...[
            const SizedBox(height: 20),
            StepUpInput(
              label: 'Number of days',
              hint: 'e.g. 45',
              controller: _customDaysCtrl,
            ).animate().fadeIn(),
            const SizedBox(height: 16),
            StepUpButton(
              label: 'Next →',
              onPressed: (int.tryParse(_customDaysCtrl.text.trim()) ?? 0) > 0
                  ? () {
                      setState(() => _wizardDays = int.parse(_customDaysCtrl.text.trim()));
                      _wizardNext();
                    }
                  : null,
            ),
          ],
        ],
      ),
    );
  }

  // ── Step 3: Daily Time ───────────────────────────────────────────
  Widget _buildStep3Time() {
    final options = [
      ('30min', '30 min/day', 'Quick focused sessions', Icons.flash_on_rounded),
      ('1h', '1 hour/day', 'Steady consistent progress', Icons.hourglass_empty_outlined),
      ('2h', '2 hours/day', 'Serious commitment', Icons.hourglass_bottom_outlined),
      ('3h+', '3+ hours/day', 'Intensive full immersion', Icons.local_fire_department_outlined),
    ];
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 140),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBackRow(),
          const SizedBox(height: 16),
          Text('Daily time available?',
              style: GoogleFonts.syne(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white))
              .animate().fadeIn(duration: 300.ms),
          const SizedBox(height: 4),
          Text('How much time can you dedicate daily?',
              style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary))
              .animate().fadeIn(delay: 80.ms),
          const SizedBox(height: 20),
          ...options.asMap().entries.map((entry) {
            final idx = entry.key;
            final id = entry.value.$1;
            final label = entry.value.$2;
            final desc = entry.value.$3;
            final icon = entry.value.$4;
            final isSelected = _wizardTime == id;
            return GestureDetector(
              onTap: () {
                setState(() => _wizardTime = id);
                HapticFeedback.lightImpact();
                Future.delayed(const Duration(milliseconds: 220), () {
                  if (mounted) _wizardNext();
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  gradient: isSelected ? AppColors.brandGradient : null,
                  color: isSelected ? null : const Color(0xFF12121A),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: isSelected ? Colors.transparent : const Color(0xFF1E1E2E)),
                  boxShadow: isSelected
                      ? [BoxShadow(color: AppColors.brand.withValues(alpha: 0.3), blurRadius: 12)]
                      : null,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.white.withValues(alpha: 0.2) : AppColors.brand.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon,
                          color: isSelected ? Colors.white : AppColors.brand, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(label,
                              style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700,
                                  color: isSelected ? Colors.white : AppColors.textPrimary)),
                          Text(desc,
                              style: GoogleFonts.inter(fontSize: 12,
                                  color: isSelected
                                      ? Colors.white.withValues(alpha: 0.75)
                                      : AppColors.textMuted)),
                        ],
                      ),
                    ),
                    if (isSelected)
                      const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                  ],
                ),
              ).animate(key: ValueKey(id)).fadeIn(delay: Duration(milliseconds: idx * 60)),
            );
          }),
        ],
      ),
    );
  }

  // ── Step 4: Current Level ────────────────────────────────────────
  Widget _buildStep4Level() {
    final options = [
      ('beginner', '🌱', 'Complete Beginner', 'Starting from zero'),
      ('some', '🌿', 'Some Knowledge', 'Know the basics'),
      ('intermediate', '🌳', 'Intermediate', 'Comfortable with fundamentals'),
      ('advanced', '🏔️', 'Advanced', 'Looking to go deep'),
    ];
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 140),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBackRow(),
          const SizedBox(height: 16),
          Text("What's your current level?",
              style: GoogleFonts.syne(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white))
              .animate().fadeIn(duration: 300.ms),
          const SizedBox(height: 4),
          Text("We'll tailor the roadmap to you",
              style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary))
              .animate().fadeIn(delay: 80.ms),
          const SizedBox(height: 20),
          ...options.asMap().entries.map((entry) {
            final idx = entry.key;
            final id = entry.value.$1;
            final emoji = entry.value.$2;
            final label = entry.value.$3;
            final desc = entry.value.$4;
            final isSelected = _wizardLevel == id;
            return GestureDetector(
              onTap: () {
                setState(() => _wizardLevel = id);
                HapticFeedback.lightImpact();
                Future.delayed(const Duration(milliseconds: 220), () {
                  if (mounted) _wizardNext();
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  gradient: isSelected ? AppColors.brandGradient : null,
                  color: isSelected ? null : const Color(0xFF12121A),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: isSelected ? Colors.transparent : const Color(0xFF1E1E2E)),
                  boxShadow: isSelected
                      ? [BoxShadow(color: AppColors.brand.withValues(alpha: 0.3), blurRadius: 12)]
                      : null,
                ),
                child: Row(
                  children: [
                    Text(emoji, style: const TextStyle(fontSize: 28)),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(label,
                              style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700,
                                  color: isSelected ? Colors.white : AppColors.textPrimary)),
                          Text(desc,
                              style: GoogleFonts.inter(fontSize: 12,
                                  color: isSelected
                                      ? Colors.white.withValues(alpha: 0.75)
                                      : AppColors.textMuted)),
                        ],
                      ),
                    ),
                    if (isSelected)
                      const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                  ],
                ),
              ).animate(key: ValueKey(id)).fadeIn(delay: Duration(milliseconds: idx * 60)),
            );
          }),
        ],
      ),
    );
  }

  // ── Step 5: Learning Style + Summary ────────────────────────────
  Widget _buildStep5Style() {
    final styles = [
      ('project', '🎯', 'Project-Based'),
      ('theory', '📚', 'Theory First'),
      ('mixed', '⚡', 'Mixed Approach'),
      ('fasttrack', '🏃', 'Fast Track'),
    ];
    final timeLabel = {
      '30min': '30 min/day', '1h': '1 hour/day',
      '2h': '2 hours/day', '3h+': '3+ hours/day',
    }[_wizardTime] ?? '1 hour/day';
    final levelLabel = {
      'beginner': 'Beginner', 'some': 'Some Knowledge',
      'intermediate': 'Intermediate', 'advanced': 'Advanced',
    }[_wizardLevel] ?? 'Beginner';
    final days = _useCustomDays
        ? (int.tryParse(_customDaysCtrl.text) ?? _wizardDays)
        : _wizardDays;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 140),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBackRow(),
          const SizedBox(height: 16),
          Text('Your learning style?',
              style: GoogleFonts.syne(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white))
              .animate().fadeIn(duration: 300.ms),
          const SizedBox(height: 4),
          Text('How do you learn best?',
              style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary))
              .animate().fadeIn(delay: 80.ms),
          const SizedBox(height: 20),
          Wrap(
            spacing: 10, runSpacing: 10,
            children: styles.map((o) {
              final id = o.$1; final emoji = o.$2; final label = o.$3;
              final isSelected = _wizardStyle == id;
              return GestureDetector(
                onTap: () => setState(() => _wizardStyle = id),
                child: _WizardChip(label: '$emoji  $label', isSelected: isSelected),
              );
            }).toList(),
          ).animate().fadeIn(delay: 100.ms),
          const SizedBox(height: 28),
          // Summary card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF12121A),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.brand.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.auto_awesome_rounded, color: AppColors.brand, size: 16),
                  const SizedBox(width: 8),
                  Text('Your roadmap summary',
                      style: GoogleFonts.spaceMono(fontSize: 12,
                          color: AppColors.brand, fontWeight: FontWeight.bold)),
                ]),
                const SizedBox(height: 12),
                _SummaryRow(label: 'Goal', value: _wizardSkillLabel()),
                _SummaryRow(label: 'Duration', value: '$days days'),
                _SummaryRow(label: 'Daily time', value: timeLabel),
                _SummaryRow(label: 'Level', value: levelLabel),
              ],
            ),
          ).animate().fadeIn(delay: 180.ms),
          const SizedBox(height: 20),
          StepUpButton(
            label: _isGeneratingAI || _isCreating
                ? 'Generating...'
                : 'Generate My Roadmap ✨',
            isLoading: _isGeneratingAI || _isCreating,
            onPressed: (_isGeneratingAI || _isCreating) ? null : _runAIGeneration,
          ).animate().fadeIn(delay: 240.ms),
        ],
      ),
    );
  }

  Widget _buildBackRow() {
    return GestureDetector(
      onTap: _wizardPrev,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.arrow_back_ios_new_rounded, size: 13, color: AppColors.textMuted),
          const SizedBox(width: 4),
          Text('Back', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}

// ─── Map Style Card ──────────────────────────────────────────────
class _MapStyleCard extends StatelessWidget {
  final String title;
  final String description;
  final String? example;
  final Widget icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _MapStyleCard({
    required this.title,
    required this.description,
    this.example,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.brand.withValues(alpha: 0.12)
              : const Color(0xFF12121A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.brand : const Color(0xFF1E1E2E),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: AppColors.brand.withValues(alpha: 0.2), blurRadius: 12)]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            icon,
            const SizedBox(height: 10),
            Text(
              title,
              style: GoogleFonts.spaceMono(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isSelected ? AppColors.brand : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            if (example != null) ...[
              const SizedBox(height: 6),
              Text(
                example!,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: AppColors.textMuted,
                  fontStyle: FontStyle.italic,
                  height: 1.3,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Linear Chain Icon ───────────────────────────────────────────
class _LinearChainIcon extends StatelessWidget {
  final Color color;
  const _LinearChainIcon({required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10, height: 10,
          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: color, width: 2)),
        ),
        Container(height: 2, width: 8, color: color),
        Container(
          width: 10, height: 10,
          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: color, width: 2)),
        ),
        Container(height: 2, width: 8, color: color),
        Container(
          width: 10, height: 10,
          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: color, width: 2)),
        ),
      ],
    );
  }
}

// ─── Branch Tree Icon ────────────────────────────────────────────
class _BranchTreeIcon extends StatelessWidget {
  final Color color;
  const _BranchTreeIcon({required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 38, height: 24,
      child: CustomPaint(painter: _BranchPainter(color: color)),
    );
  }
}

class _BranchPainter extends CustomPainter {
  final Color color;
  const _BranchPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final fill = Paint()..color = color..style = PaintingStyle.fill;

    // Root node
    canvas.drawCircle(Offset(6, size.height / 2), 4, fill);
    // Main trunk
    canvas.drawLine(Offset(10, size.height / 2), Offset(18, size.height / 2), paint);
    // Branch up
    canvas.drawLine(Offset(18, size.height / 2), Offset(22, 4), paint);
    canvas.drawCircle(Offset(26, 4), 3.5, paint);
    // Branch middle
    canvas.drawLine(Offset(18, size.height / 2), Offset(26, size.height / 2), paint);
    canvas.drawCircle(Offset(30, size.height / 2), 3.5, paint);
    // Branch down
    canvas.drawLine(Offset(18, size.height / 2), Offset(22, size.height - 4), paint);
    canvas.drawCircle(Offset(26, size.height - 4), 3.5, paint);
  }

  @override
  bool shouldRepaint(covariant _BranchPainter old) => old.color != color;
}

// ─── Manual Level Tile ───────────────────────────────────────────
class _ManualLevelTile extends StatelessWidget {
  final _ManualLevel lvl;
  final int index;
  final bool showSubLevels;
  final VoidCallback onDelete;
  final VoidCallback onProofTypeCycle;
  final VoidCallback onToggleExpanded;
  final VoidCallback onAddSubLevel;
  final void Function(int) onDeleteSubLevel;
  final void Function(int) onSubProofCycle;
  final VoidCallback onRebuild;

  const _ManualLevelTile({
    required super.key,
    required this.lvl,
    required this.index,
    required this.showSubLevels,
    required this.onDelete,
    required this.onProofTypeCycle,
    required this.onToggleExpanded,
    required this.onAddSubLevel,
    required this.onDeleteSubLevel,
    required this.onSubProofCycle,
    required this.onRebuild,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF12121A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1E1E2E)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main level row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.drag_indicator, color: AppColors.textMuted, size: 20),
                const SizedBox(width: 8),
                CircleAvatar(
                  radius: 12,
                  backgroundColor: AppColors.brand.withValues(alpha: 0.15),
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
                const SizedBox(width: 6),
                _ProofTypeCycleChip(
                  proofType: lvl.proofType,
                  onCycle: onProofTypeCycle,
                ),
                if (showSubLevels) ...[
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: onToggleExpanded,
                    child: Icon(
                      lvl.isExpanded ? Icons.expand_less : Icons.expand_more,
                      color: AppColors.textMuted,
                      size: 20,
                    ),
                  ),
                ],
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 18),
                  onPressed: onDelete,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ),

          // Sub-levels section (only in sublevels mode + expanded)
          if (showSubLevels && lvl.isExpanded) ...[
            const Divider(height: 1, color: Color(0xFF1E1E2E)),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 12, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (int si = 0; si < lvl.subLevels.length; si++)
                    _SubLevelRow(
                      subLevel: lvl.subLevels[si],
                      label: '${index + 1}.${si + 1}',
                      onDelete: () => onDeleteSubLevel(si),
                      onProofCycle: () => onSubProofCycle(si),
                    ),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: onAddSubLevel,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_circle_outline, size: 14, color: AppColors.brand.withValues(alpha: 0.8)),
                        const SizedBox(width: 6),
                        Text(
                          '+ Add Sub-topic',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.brand,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Sub-Level Row ───────────────────────────────────────────────
class _SubLevelRow extends StatelessWidget {
  final _ManualSubLevel subLevel;
  final String label;
  final VoidCallback onDelete;
  final VoidCallback onProofCycle;

  const _SubLevelRow({
    required this.subLevel,
    required this.label,
    required this.onDelete,
    required this.onProofCycle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(
              label,
              style: GoogleFonts.spaceMono(
                fontSize: 10,
                color: AppColors.brand.withValues(alpha: 0.8),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: TextField(
              controller: subLevel.controller,
              style: GoogleFonts.inter(fontSize: 13, color: AppColors.textPrimary),
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
                hintText: 'Sub-topic title',
                hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 13),
              ),
            ),
          ),
          const SizedBox(width: 6),
          _ProofTypeCycleChip(proofType: subLevel.proofType, onCycle: onProofCycle),
          GestureDetector(
            onTap: onDelete,
            child: const Padding(
              padding: EdgeInsets.only(left: 6),
              child: Icon(Icons.close, size: 14, color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Wizard Chip ─────────────────────────────────────────────────
class _WizardChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final IconData? icon;

  const _WizardChip({
    required this.label,
    required this.isSelected,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        gradient: isSelected ? AppColors.brandGradient : null,
        color: isSelected ? null : const Color(0xFF12121A),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isSelected ? Colors.transparent : const Color(0xFF1E1E2E),
        ),
        boxShadow: isSelected
            ? [BoxShadow(color: AppColors.brand.withValues(alpha: 0.3), blurRadius: 8)]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon!, size: 14,
                color: isSelected ? Colors.white : AppColors.textSecondary),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Summary Row ─────────────────────────────────────────────────
class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  const _SummaryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted)),
          Text(value,
              style: GoogleFonts.inter(
                  fontSize: 12, fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}
