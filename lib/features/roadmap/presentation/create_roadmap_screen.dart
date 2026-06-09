import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  bool _isCreating = false; // Separate from provider isLoading for button UX
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
      // ── Check for user-stored OpenAI API key ─────────────────
      final prefs = await SharedPreferences.getInstance();
      final apiKey = prefs.getString('openai_api_key') ?? '';

      if (apiKey.isNotEmpty) {
        // ── Real OpenAI call ──────────────────────────────────
        final openAiDio = Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 20),
          receiveTimeout: const Duration(seconds: 30),
        ));
        final prompt = '''
You are a professional learning-path designer. Create a structured roadmap for: "$title".
Description/context: "${_aiGoalDescCtrl.text.trim()}".
Type: $_selectedType.

Return ONLY valid JSON with this exact shape — no markdown, no explanation:
{
  "levels": [
    {
      "levelNumber": 1,
      "title": "...",
      "description": "...",
      "proofType": "quiz|timer|code",
      "estimatedMinutes": 45,
      "xpReward": 100
    }
  ]
}

Rules:
- Between 6 and 12 levels
- Titles must be specific and actionable (no generic "Introduction" alone)
- proofType: quiz for theory, code for coding tasks, timer for physical/time-based tasks
- xpReward: 100 for easy, 150 for medium, 200-300 for hard/final levels
''';
        final aiResponse = await openAiDio.post(
          'https://api.openai.com/v1/chat/completions',
          options: Options(
            headers: {
              'Authorization': 'Bearer $apiKey',
              'Content-Type': 'application/json',
            },
          ),
          data: {
            'model': 'gpt-4o-mini',
            'messages': [
              {'role': 'system', 'content': 'You are a concise JSON-only API. Return only valid JSON.'},
              {'role': 'user', 'content': prompt},
            ],
            'temperature': 0.7,
            'max_tokens': 2000,
          },
        );
        final content = aiResponse.data['choices'][0]['message']['content'] as String;
        // Strip possible markdown code fences
        final cleaned = content
            .replaceAll('```json', '')
            .replaceAll('```', '')
            .trim();
        final parsed = jsonDecode(cleaned) as Map<String, dynamic>;
        final levels = (parsed['levels'] as List<dynamic>)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();

        setState(() {
          _isGeneratingAI = false;
          _generatedLevelsPreview = levels;
          _clearPreviewControllers();
          for (final lvl in levels) {
            _previewControllers
                .add(TextEditingController(text: lvl['title']));
          }
        });
        return;
      }

      // ── No API key: use smart local templates ─────────────
      throw Exception('no_key');
    } catch (_) {
      // Fallback: local template with short simulated delay
      await Future.delayed(const Duration(milliseconds: 800));
      final levels = _generateSmartRoadmap(
        title, _aiGoalDescCtrl.text.trim(), _selectedType);
      if (mounted) {
        setState(() {
          _isGeneratingAI = false;
          _generatedLevelsPreview = levels;
          _clearPreviewControllers();
          for (final lvl in levels) {
            _previewControllers
                .add(TextEditingController(text: lvl['title'] as String));
          }
        });
      }
    } finally {
      _loadingTimer?.cancel();
    }
  }

  Future<void> _saveAI() async {
    if (_generatedLevelsPreview == null) return;
    setState(() => _isCreating = true);

    final title = _aiGoalTitleCtrl.text.trim();
    final description = _aiGoalDescCtrl.text.trim();

    // Read updated level titles from preview controllers
    final List<Map<String, dynamic>> finalizedLevels = [];
    for (int i = 0; i < _generatedLevelsPreview!.length; i++) {
      final item = Map<String, dynamic>.from(_generatedLevelsPreview![i]);
      item['title'] = _previewControllers[i].text.trim();
      finalizedLevels.add(item);
    }

    final payload = {
      'title': title,
      'description': description.isNotEmpty
          ? description
          : 'AI generated roadmap for $title',
      'type': _selectedType,
      'source': 'ai',
      'examMode': false,
      'levels': finalizedLevels,
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
            content: Text('Failed to save roadmap. Please try again.')),
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

  @override
  Widget build(BuildContext context) {
    // Use local _isCreating instead of provider isLoading for button state
    // so only the tapped button spins, not every button on the page.
    final roadmapState = ref.watch(roadmapProvider);
    // Re-use provider error if needed
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
                    style: GoogleFonts.inter(
                        fontSize: 14, color: AppColors.textSecondary)),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    itemCount: _generatedLevelsPreview!.length,
                    itemBuilder: (ctx, index) {
                      final lvl = _generatedLevelsPreview![index];
                      final proof = lvl['proofType'] as String? ?? 'quiz';
                      final xp = lvl['xpReward'] as int? ?? 100;
                      final mins = lvl['estimatedMinutes'] as int? ?? 45;
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
                              backgroundColor:
                                  AppColors.brand.withOpacity(0.2),
                              child: Text(
                                '${index + 1}',
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.brand,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  TextField(
                                    controller: _previewControllers[index],
                                    style: GoogleFonts.inter(
                                        fontSize: 14, color: Colors.white),
                                    decoration: const InputDecoration(
                                      border: InputBorder.none,
                                      isDense: true,
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Text(
                                        '$proof • ${mins}m • $xp XP',
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          color: AppColors.textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
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
                  label: _isCreating ? 'Saving Roadmap...' : 'Save & Start Roadmap Map 🚀',
                  isLoading: _isCreating,
                  onPressed: _isCreating ? null : _saveAI,
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
                  label: _isCreating ? 'Creating Roadmap...' : 'Create Roadmap Map 🚀',
                  isLoading: _isCreating,
                  onPressed: _isCreating ? null : _createManual,
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
                // AI key status banner
                FutureBuilder<String>(
                  future: SharedPreferences.getInstance().then(
                    (prefs) => prefs.getString('openai_api_key') ?? ''),
                  builder: (ctx, snap) {
                    final hasKey =
                        (snap.data ?? '').isNotEmpty;
                    return Container(
                      padding: const EdgeInsets.all(AppSpacing.base),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: hasKey
                              ? [
                                  const Color(0xFF0D2B1A),
                                  const Color(0xFF12121A)
                                ]
                              : [
                                  const Color(0xFF1A1040),
                                  const Color(0xFF12121A)
                                ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: hasKey
                              ? AppColors.green.withOpacity(0.4)
                              : AppColors.brand.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(
                            hasKey ? '✅' : '✨',
                            style: const TextStyle(fontSize: 24),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  hasKey
                                      ? 'OpenAI API active'
                                      : 'Smart Local Generation',
                                  style: GoogleFonts.spaceMono(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: hasKey
                                        ? AppColors.green
                                        : AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  hasKey
                                      ? 'Your OpenAI key will generate a custom roadmap.'
                                      : 'No API key? No problem — expert templates built in. Add key in Settings for real AI.',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                if (!hasKey) ...
                                  [
                                    const SizedBox(height: 6),
                                    GestureDetector(
                                      onTap: () =>
                                          context.push(AppRoutes.settings),
                                      child: Text(
                                        'Add OpenAI key →',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.brand,
                                        ),
                                      ),
                                    ),
                                  ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
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
                  isLoading: _isGeneratingAI,
                  onPressed: _isGeneratingAI ? null : _generateAI,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
