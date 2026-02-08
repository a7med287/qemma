import 'package:flutter/material.dart';

import '../utils/app_colors.dart';

class CustomTextFormField extends StatefulWidget {
  const CustomTextFormField({
    super.key,
    this.onSaved,
     this.iconData,
    required this.textInputType,
    this.textController,
    required this.labelText,
    this.onChanged,
  });

  final void Function(String?)? onSaved;
  final IconData? iconData;
  final TextInputType textInputType;
  final String labelText;
  final TextEditingController? textController;
  final void Function(String)? onChanged;


  @override
  State<CustomTextFormField> createState() => _CustomTextFormFieldState();
}

class _CustomTextFormFieldState extends State<CustomTextFormField> {
  late FocusNode focusNode;
  bool isFocused = false;

  @override
  void initState() {
    super.initState();
    focusNode = FocusNode();
    focusNode.addListener(() {
      setState(() {
        isFocused = focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.textController,
      focusNode: focusNode,
      validator: (value) {
        if (value!.isEmpty) {
          return "${widget.labelText} مطلوب ";
        }
        return null;
      },
      onSaved: widget.onSaved,
      onChanged: widget.onChanged,
      keyboardType: widget.textInputType,

      decoration: InputDecoration(



        label: Text(
          widget.labelText,
          style: TextStyle(
            color: isFocused ? Colors.black : Colors.grey,
          ),
        ),
        prefixIcon: Icon(
          widget.iconData,
          color: isFocused ? AppColors.primaryColor : Colors.grey,
        ),
        border: buildOutlineInputBorder(),
        enabledBorder: buildOutlineInputBorder(),
        focusedBorder: buildOutlineInputBorder(color: AppColors.primaryColor),
          contentPadding: const EdgeInsets.fromLTRB(24, 13, 20, 13),
      ),
    );
  }

  OutlineInputBorder buildOutlineInputBorder({Color color = Colors.grey}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: color),
    );
  }
}
