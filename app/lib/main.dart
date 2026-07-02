import 'bootstrap.dart';

/// Application entry point.
///
/// All real startup logic lives in [bootstrap] so the entry point stays a
/// single, unambiguous call. Alternative entry points (e.g. flavored mains or
/// integration-test harnesses) can reuse [bootstrap] without duplication.
void main() => bootstrap();
