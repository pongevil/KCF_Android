import 'package:flutter/material.dart';

class TextFieldSelectionHelper {
  const TextFieldSelectionHelper._();

  static void selectAll(TextEditingController controller) {
    final text = controller.text;
    if (text.isEmpty) {
      return;
    }

    controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: text.length,
    );
  }

  static void selectAllAfterFrame(TextEditingController controller) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      selectAll(controller);
    });
  }
}
