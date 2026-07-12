import 'package:flutter/material.dart';
import 'package:get/get.dart'; 
import 'package:weather_admin_dashboard/app/theme/phosphor_icons.dart'; 
import 'package:weather_admin_dashboard/app/controllers/weather_conditions_controller.dart'; // Ensure this path is correct


// --- VIEW ---
class AddWeatherConditionsView extends StatelessWidget {
  const AddWeatherConditionsView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(WeatherConditionsController());

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Input Form matching Theme
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller.conditionController,
                    decoration: InputDecoration(
                      hintText: 'e.g., Heavy Rain, Partly Cloudy...',
                      prefixIcon: Icon(PhosphorIcons.cloud(), color: Theme.of(context).hintColor),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Theme.of(context).dividerColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Theme.of(context).dividerColor),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    onSubmitted: (_) => controller.addCondition(),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: controller.addCondition,
                  icon: Icon(PhosphorIcons.plus(), size: 18),
                  label: const Text('Add Condition'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          Text(
            'Department Weather Conditions',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),

          // Display List
          Expanded(
            child: Obx(() {
              print("Current conditions in controller: ${controller.conditions.length}"); // Debugging line
              if (controller.conditions.isEmpty) {
                return _EmptyStateIndicator(
                  icon: PhosphorIcons.cloudSlash(),
                  message: 'No weather conditions configured for your department yet.',
                );
              }
              return ListView.builder(
                itemCount: controller.conditions.length,
                itemBuilder: (context, index) {
                  // Now item is just a String!
                  final String conditionName = controller.conditions[index];
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.5)),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(PhosphorIcons.cloudSun(), color: Theme.of(context).primaryColor),
                      ),
                      title: Text(
                        conditionName, // Pass the string directly
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      trailing: IconButton(
                        icon: Icon(PhosphorIcons.trash(), color: Colors.redAccent, size: 20),
                        tooltip: 'Delete Condition',
                        onPressed: () => controller.deleteCondition(conditionName), // Pass the string directly
                      ),
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}

// Helper Widget for Empty States
class _EmptyStateIndicator extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptyStateIndicator({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Theme.of(context).dividerColor),
          const SizedBox(height: 16),
          Text(
            message, 
            style: TextStyle(color: Theme.of(context).hintColor, fontSize: 16)
          ),
        ],
      ),
    );
  }
}