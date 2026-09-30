import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants/app_info.dart';
import '../theme/app_colors.dart';

class AppSupportFooter extends StatelessWidget {
  const AppSupportFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Center(
        child: Material(
          color: Colors.white,
          elevation: 1,
          shadowColor: AppColors.line,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            onTap: () => launchUrl(Uri.parse(AppInfo.websiteUrl), mode: LaunchMode.externalApplication),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.line.withValues(alpha: 0.6)),
              ),
              child: const Directionality(
                textDirection: TextDirection.ltr,
                child: Text(
                  AppInfo.website,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}