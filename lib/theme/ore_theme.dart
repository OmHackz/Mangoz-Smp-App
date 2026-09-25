import 'package:flutter/widgets.dart';
import 'package:oreui_flutter/oreui_flutter.dart';

/// Re-exports Ore theme helpers so the rest of the app has one import.
export 'package:oreui_flutter/oreui_flutter.dart'
    show
        OreTheme,
        OreThemeData,
        OreThemeBuilder,
        OreThemeController,
        OreButton,
        OreButtonVariant,
        OreButtonSize,
        OreCard,
        OreTextField,
        OreSwitch,
        OreCheckbox,
        OreSlider,
        OreDropdownButton,
        OreDropdownItem,
        OreLoadingIndicator,
        OreStrip,
        OreSurface,
        OreDivider;

OreThemeData oreOf(BuildContext context) => OreTheme.of(context);
