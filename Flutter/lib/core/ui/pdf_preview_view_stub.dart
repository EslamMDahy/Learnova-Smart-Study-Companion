void registerPdfPreviewView({
  required String viewType,
  required String url,
  required bool interactive,
  int? pageStart,
  int? pageEnd,
}) {}

void updatePdfPreviewSource({
  required String viewType,
  required String url,
  required bool interactive,
  int? pageStart,
  int? pageEnd,
}) {}

void updatePdfPreviewInteractivity({
  required String viewType,
  required bool interactive,
}) {}

void scrollPdfPreviewToPage({
  required String viewType,
  required int page,
}) {}
