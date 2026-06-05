/// Form field validators for STEPUP app.
class Validators {
  Validators._();

  // ── Email ─────────────────────────────────────────────────────

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }

  // ── Password ──────────────────────────────────────────────────

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Include at least one uppercase letter';
    }
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Include at least one number';
    }
    return null;
  }

  static String? confirmPassword(String? value, String original) {
    final base = password(value);
    if (base != null) return base;
    if (value != original) return 'Passwords do not match';
    return null;
  }

  // ── Name ──────────────────────────────────────────────────────

  static String? name(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Name is required';
    }
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }
    if (value.trim().length > 50) {
      return 'Name must be under 50 characters';
    }
    return null;
  }

  // ── Required ──────────────────────────────────────────────────

  static String? required(String? value, [String? fieldName]) {
    if (value == null || value.trim().isEmpty) {
      return '${fieldName ?? 'This field'} is required';
    }
    return null;
  }

  // ── Min / Max length ──────────────────────────────────────────

  static String? Function(String?) minLength(int min, [String? field]) {
    return (String? value) {
      if (value == null || value.trim().length < min) {
        return '${field ?? 'Field'} must be at least $min characters';
      }
      return null;
    };
  }

  static String? Function(String?) maxLength(int max, [String? field]) {
    return (String? value) {
      if (value != null && value.trim().length > max) {
        return '${field ?? 'Field'} must be under $max characters';
      }
      return null;
    };
  }

  // ── URL ───────────────────────────────────────────────────────

  static String? url(String? value) {
    if (value == null || value.trim().isEmpty) return null; // optional
    final urlRegex = RegExp(
      r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}'
      r'\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$',
    );
    if (!urlRegex.hasMatch(value.trim())) {
      return 'Enter a valid URL (https://...)';
    }
    return null;
  }

  // ── Roadmap title ─────────────────────────────────────────────

  static String? roadmapTitle(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Roadmap title is required';
    }
    if (value.trim().length < 3) {
      return 'Title must be at least 3 characters';
    }
    if (value.trim().length > 100) {
      return 'Title must be under 100 characters';
    }
    return null;
  }

  // ── Compose multiple validators ───────────────────────────────

  static String? Function(String?) compose(
    List<String? Function(String?)> validators,
  ) {
    return (String? value) {
      for (final validator in validators) {
        final error = validator(value);
        if (error != null) return error;
      }
      return null;
    };
  }
}
