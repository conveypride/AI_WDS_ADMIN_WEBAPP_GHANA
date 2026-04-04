import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:weather_admin_dashboard/app/controllers/cities_controller.dart';

class AddCitiesView extends StatelessWidget {
  const AddCitiesView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(CitiesController());

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // UI Matching your AdminLayout (Clean Card, subtle borders)
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
                    controller: controller.cityController,
                    decoration: InputDecoration(
                      hintText: 'Enter new city name...',
                      prefixIcon: Icon(PhosphorIcons.mapPin(), color: Theme.of(context).hintColor),
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
                    onSubmitted: (_) => controller.addCity(),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: controller.addCity,
                  icon: Icon(PhosphorIcons.plus(), size: 18),
                  label: const Text('Add City'),
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
            'Department Cities',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),

          // Display List
          Expanded(
            child: Obx(() {
              if (controller.cities.isEmpty) {
                return _EmptyStateIndicator(
                  icon: PhosphorIcons.mapTrifold(),
                  message: 'No cities configured for your department yet.',
                );
              }
              print("Current cities in controller: ${controller.cities.length}"); // Debugging line
              
              return ListView.builder(
                itemCount: controller.cities.length,
                itemBuilder: (context, index) {
                  // Now handling the list of strings directly
                  final String cityName = controller.cities[index];
                  
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
                        child: Icon(PhosphorIcons.buildings(), color: Theme.of(context).primaryColor),
                      ),
                      title: Text(
                        cityName, // Direct string usage
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      trailing: IconButton(
                        icon: Icon(PhosphorIcons.trash(), color: Colors.redAccent, size: 20),
                        onPressed: () => controller.deleteCity(cityName), // Pass the string directly to delete function
                        tooltip: 'Remove City',
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