import 'package:flutter/material.dart';

import 'app/app.dart';
import 'data/mock/in_memory_trip_repositories.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(TripSplitApp(repositories: InMemoryTripRepositories()));
}
