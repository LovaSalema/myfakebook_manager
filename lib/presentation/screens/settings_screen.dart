import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../providers/theme_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_colors.dart';

/// Settings screen for application preferences
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: isDark
          ? Color(AppColors.backgroundDark)
          : Color(AppColors.backgroundLight),
      appBar: AppBar(
        backgroundColor: isDark
            ? Color(AppColors.backgroundDark)
            : Color(AppColors.backgroundLight),
        elevation: 2,
        shadowColor: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
        title: Text(
          'Paramètres',
          style: TextStyle(color: Theme.of(context).colorScheme.primary),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).colorScheme.primary,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isLandscape = constraints.maxWidth > constraints.maxHeight;

            return SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(16.r),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Theme Section
                    _buildThemeSection(context, themeProvider, isLandscape),

                    SizedBox(height: 24.h),

                    // App Information Section
                    _buildAppInfoSection(context, isLandscape),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// Build theme section with dark/light mode toggle
  Widget _buildThemeSection(
    BuildContext context,
    ThemeProvider themeProvider,
    bool isLandscape,
  ) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: EdgeInsets.all(16.r),
        child: isLandscape
            ? Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          Icons.palette,
                          size: 24.sp,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        SizedBox(width: 12.w),
                        Text(
                          'Thème',
                          style: AppTextStyles.titleMedium.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(child: _buildThemeToggle(context, themeProvider)),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.palette,
                        size: 24.sp,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      SizedBox(width: 12.w),
                      Text(
                        'Thème',
                        style: AppTextStyles.titleMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16.h),
                  _buildThemeToggle(context, themeProvider),
                ],
              ),
      ),
    );
  }

  /// Build theme toggle switch
  Widget _buildThemeToggle(BuildContext context, ThemeProvider themeProvider) {
    return Card(
      elevation: 1,
      child: SwitchListTile(
        title: Text(
          'Mode sombre',
          style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          themeProvider.isDarkMode
              ? 'Interface en mode sombre'
              : 'Interface en mode clair',
          style: AppTextStyles.bodyMedium.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        value: themeProvider.isDarkMode,
        onChanged: (value) {
          themeProvider.setThemeMode(value ? ThemeMode.dark : ThemeMode.light);
        },
        secondary: Icon(
          themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
          color: themeProvider.isDarkMode
              ? Colors.blue.shade400
              : Colors.orange.shade500,
        ),
        activeColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  /// Build app information section
  Widget _buildAppInfoSection(BuildContext context, bool isLandscape) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: EdgeInsets.all(16.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info,
                  size: 24.sp,
                  color: Theme.of(context).colorScheme.primary,
                ),
                SizedBox(width: 12.w),
                Text(
                  'Informations',
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            if (isLandscape)
              Row(
                children: [
                  Expanded(
                    child: _buildInfoItem(
                      context: context,
                      title: 'Version',
                      value: '1.0.0',
                      icon: Icons.apps,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: _buildInfoItem(
                      context: context,
                      title: 'Développeur',
                      value: 'MyFakeBook Team',
                      icon: Icons.code,
                    ),
                  ),
                ],
              )
            else
              Column(
                children: [
                  _buildInfoItem(
                    context: context,
                    title: 'Version',
                    value: '1.0.0',
                    icon: Icons.apps,
                  ),
                  SizedBox(height: 12.h),
                  _buildInfoItem(
                    context: context,
                    title: 'Développeur',
                    value: 'MyFakeBook Team',
                    icon: Icons.code,
                  ),
                ],
              ),
            SizedBox(height: 12.h),
            _buildInfoItem(
              context: context,
              title: 'Contact',
              value: 'support@myfakebook.com',
              icon: Icons.email,
            ),
          ],
        ),
      ),
    );
  }

  /// Build individual info item
  Widget _buildInfoItem({
    required BuildContext context,
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20.sp,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  value,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
