import 'package:flutter/material.dart';



import '../theme/app_colors.dart';



class AppCard extends StatelessWidget {

  const AppCard({

    super.key,

    required this.child,

    this.padding = const EdgeInsets.all(16),

    this.onTap,

  });



  final Widget child;

  final EdgeInsets padding;

  final VoidCallback? onTap;



  @override

  Widget build(BuildContext context) {

    final body = Container(

      padding: padding,

      decoration: BoxDecoration(

        color: AppColors.surface,

        borderRadius: BorderRadius.circular(18),

        border: Border.all(color: AppColors.line),

        boxShadow: [

          BoxShadow(

            color: AppColors.primary.withValues(alpha: 0.06),

            blurRadius: 16,

            offset: const Offset(0, 6),

          ),

          BoxShadow(

            color: Colors.black.withValues(alpha: 0.04),

            blurRadius: 4,

            offset: const Offset(0, 2),

          ),

        ],

      ),

      child: child,

    );

    if (onTap == null) {

      return body;

    }

    return InkWell(

      onTap: onTap,

      borderRadius: BorderRadius.circular(18),

      child: body,

    );

  }

}

