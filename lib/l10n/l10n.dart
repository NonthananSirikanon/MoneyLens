import 'package:flutter/widgets.dart';

import 'app_localizations.dart';

export 'app_localizations.dart';

extension L10nContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);

  /// Locale tag used for number and date formatting.
  String get localeTag => Localizations.localeOf(this).toLanguageTag();
}
