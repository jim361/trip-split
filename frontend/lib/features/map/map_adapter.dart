import 'package:flutter/widgets.dart';

import 'map_render_model.dart';

typedef MapViewBuilder = Widget Function({
  required String viewId,
  required MapRenderModel model,
  required ValueChanged<String> onSelect,
});
