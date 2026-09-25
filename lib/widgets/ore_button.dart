import 'package:flutter/widgets.dart';
import 'package:oreui_flutter/oreui_flutter.dart';

/// Primary MangoZ button — always uses [OreButton], never a Material clone.
class MangoOreButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final OreButtonVariant variant;
  final OreButtonSize size;
  final bool isLoading;
  final bool fullWidth;

  const MangoOreButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.variant = OreButtonVariant.secondary,
    this.size = OreButtonSize.md,
    this.isLoading = false,
    this.fullWidth = false,
  });

  factory MangoOreButton.primary({
    Key? key,
    required String label,
    required VoidCallback? onPressed,
    bool isLoading = false,
    bool fullWidth = false,
  }) {
    return MangoOreButton(
      key: key,
      onPressed: onPressed,
      variant: OreButtonVariant.primary,
      isLoading: isLoading,
      fullWidth: fullWidth,
      child: Text(label),
    );
  }

  factory MangoOreButton.danger({
    Key? key,
    required String label,
    required VoidCallback? onPressed,
    bool isLoading = false,
  }) {
    return MangoOreButton(
      key: key,
      onPressed: onPressed,
      variant: OreButtonVariant.danger,
      isLoading: isLoading,
      child: Text(label),
    );
  }

  @override
  Widget build(BuildContext context) {
    return OreButton(
      onPressed: isLoading ? null : onPressed,
      variant: variant,
      size: size,
      isLoading: isLoading,
      fullWidth: fullWidth,
      child: child,
    );
  }
}
