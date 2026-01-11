import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_primary_button.dart';
import '../../core/widgets/app_text.dart';
import '../../parent_viewmodels/auth_vm.dart';
import '../../parent_viewmodels/location_vm.dart';
import '../../parent_viewmodels/parent_signup_vm.dart';
import 'login_screen.dart';


class LocationSelectionScreen extends StatelessWidget {
  /// Parent flow se aa raha ho? → true
  /// Tutor ka standalone location step ho? → false
  final bool showStepIndicator;

  /// Parent flow me kaunsa step (0-based index)
  /// e.g. agar yeh 4th step hai to 3
  final int? stepIndex;

  /// Button text (default: "Save")
  final String buttonLabel;

  /// If true, returns location data via Navigator.pop instead of navigating
  final bool returnLocation;

  /// Initial location to display (for editing existing location)
  final double? initialLatitude;
  final double? initialLongitude;
  final String? initialAddress;

  const LocationSelectionScreen({
    super.key,
    this.showStepIndicator = false,
    this.stepIndex,
    this.buttonLabel = 'Save',
    this.returnLocation = false,
    this.initialLatitude,
    this.initialLongitude,
    this.initialAddress,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LocationViewModel(
        initialLatitude: initialLatitude,
        initialLongitude: initialLongitude,
        initialAddress: initialAddress,
      ),
      child: _LocationSelectionView(
        showStepIndicator: showStepIndicator,
        stepIndex: stepIndex,
        buttonLabel: buttonLabel,
        returnLocation: returnLocation,
      ),
    );
  }
}

class _LocationSelectionView extends StatelessWidget {
  final bool showStepIndicator;
  final int? stepIndex;
  final String buttonLabel;
  final bool returnLocation;

  const _LocationSelectionView({
    required this.showStepIndicator,
    required this.stepIndex,
    required this.buttonLabel,
    required this.returnLocation,
  });

  /// Build markers for the map
  /// Use const constructor where possible to prevent unnecessary rebuilds
  Set<Marker> _buildMarkers(LocationViewModel vm) {
    if (vm.latitude.isEmpty || vm.longitude.isEmpty) {
      return const {};
    }

    final lat = double.tryParse(vm.latitude);
    final lng = double.tryParse(vm.longitude);

    if (lat == null || lng == null) {
      return const {};
    }

    return {
      Marker(
        markerId: const MarkerId('selected_location'),
        position: LatLng(lat, lng),
        draggable: true,
        onDragEnd: (LatLng position) {
          vm.onMapTap(position);
        },
      ),
    };
  }

  /// Build fallback UI when Google Maps fails to load (e.g., billing issue)
  Widget _buildMapErrorFallback(LocationViewModel vm, dynamic error) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.map_outlined,
            size: 48,
            color: AppColors.error,
          ),
          const SizedBox(height: 16),
          AppText(
            'Map Not Available',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          AppText(
            kIsWeb
                ? 'Google Maps requires billing to be enabled.\nPlease use the search bar or enter coordinates manually below.'
                : 'Unable to load map. Please enter coordinates manually below.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textGrey,
            ),
          ),
          if (kDebugMode) ...[
            const SizedBox(height: 12),
            AppText(
              'Error: ${error.toString()}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.error,
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<LocationViewModel>();
    final theme = Theme.of(context);
    final vm1 = context.watch<AuthViewModel>();
    final ParentSignupViewModel? pvm =
        showStepIndicator ? context.watch<ParentSignupViewModel>() : null;

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: AppText(
          'Select Your Location',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
          },
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 🔵 Parent flow ho to StepIndicator dikhayein
              if (showStepIndicator && stepIndex != null) ...[
                // StepIndicator(
                //   totalSteps: 4,
                //   currentIndex: stepIndex!,
                // ),
                const SizedBox(height: 24),
              ],

              // Search bar


              // Use my current location

              const SizedBox(height: 30),

              // Google Map with error handling for billing issues
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  height: 260,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      width: 2,
                    ),
                  ),
                  child: Builder(
                    builder: (context) {
                      // For web platform, check if Google Maps is available
                      if (kIsWeb) {
                        try {
                          return Stack(
                            children: [
                              GoogleMap(
                                initialCameraPosition: vm.cameraPosition,
                                onMapCreated: (GoogleMapController controller) {
                                  vm.setMapController(controller);
                                },
                                onTap: (LatLng position) {
                                  vm.onMapTap(position);
                                },
                                onCameraMove: (CameraPosition position) {
                                  vm.onCameraMove(position);
                                },
                                onCameraIdle: () {
                                  vm.onCameraIdle();
                                },
                                myLocationButtonEnabled: false,
                                myLocationEnabled: true,
                                zoomControlsEnabled: true,
                                zoomGesturesEnabled: true,
                                mapToolbarEnabled: false,
                                markers: _buildMarkers(vm),
                                mapType: MapType.normal,
                                compassEnabled: false,
                                rotateGesturesEnabled: true,
                                scrollGesturesEnabled: true,
                                tiltGesturesEnabled: false,
                                gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                                  Factory<OneSequenceGestureRecognizer>(() => EagerGestureRecognizer()),
                                },
                              ),
                              Center(
                                child: Icon(
                                  Icons.location_on,
                                  color: AppColors.primary,
                                  size: 40,
                                ),
                              ),
                            ],
                          );
                        } catch (e) {
                          // Fallback UI if Google Maps fails to load (e.g., billing issue)
                          return _buildMapErrorFallback(vm, e);
                        }
                      } else {
                        // Mobile platforms - normal map rendering
                        return Stack(
                          children: [
                            GoogleMap(
                              initialCameraPosition: vm.cameraPosition,
                              onMapCreated: (GoogleMapController controller) {
                                vm.setMapController(controller);
                              },
                              onTap: (LatLng position) {
                                vm.onMapTap(position);
                              },
                              onCameraMove: (CameraPosition position) {
                                vm.onCameraMove(position);
                              },
                              onCameraIdle: () {
                                vm.onCameraIdle();
                              },
                              myLocationButtonEnabled: false,
                              myLocationEnabled: true,
                              zoomControlsEnabled: true,
                              zoomGesturesEnabled: true,
                              mapToolbarEnabled: false,
                              markers: _buildMarkers(vm),
                              mapType: MapType.normal,
                              compassEnabled: false,
                              rotateGesturesEnabled: true,
                              scrollGesturesEnabled: true,
                              tiltGesturesEnabled: false,
                              gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                                Factory<OneSequenceGestureRecognizer>(() => EagerGestureRecognizer()),
                              },
                            ),
                            Center(
                              child: Icon(
                                Icons.location_on,
                                color: AppColors.primary,
                                size: 40,
                              ),
                            ),
                          ],
                        );
                      }
                    },
                  ),
                ),
              ),
              if (vm.selectedAddress != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                  color: AppColors.lightBackground,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                  child: AppText(
                          vm.selectedAddress!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.textDark,
                    ),
                  ),
                ),
                    ],
              ),
                ),
              ],
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () {
                  vm.getCurrentLocation();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.lightBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (vm.isLoadingLocation)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                          ),
                        )
                      else
                        Icon(
                          Icons.my_location,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      const SizedBox(width: 8),
                      AppText(
                        vm.isLoadingLocation
                            ? 'Detecting your location...'
                            : 'Use My Current Location',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              AppPrimaryButton(
                label: buttonLabel,
                isLoading: showStepIndicator
                    ? (pvm?.isLoading ?? false)
                    : (returnLocation ? false : vm1.isLoading),
                isDisabled: showStepIndicator
                    ? !(vm.canSave && (pvm?.isStep3Valid ?? false))
                    : (returnLocation ? !vm.canSave : !vm1.canSubmitParentSignup),
                onPressed: () async {
                  if (showStepIndicator && pvm != null) {
                    // Parent 4-step flow: Use ParentSignupViewModel
                    if (kDebugMode) {
                      print('📍 LocationSelectionScreen: Submitting parent signup');
                      print('   vm.latitude (String): "${vm.latitude}"');
                      print('   vm.longitude (String): "${vm.longitude}"');
                    }
                    
                    final lat = double.tryParse(vm.latitude);
                    final lng = double.tryParse(vm.longitude);

                    if (kDebugMode) {
                      print('   Parsed lat: $lat');
                      print('   Parsed lng: $lng');
                    }

                    if (lat == null || lng == null) {
                      Get.snackbar(
                        'Invalid Input',
                        'Please enter valid coordinates.',
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: AppColors.error,
                        colorText: Colors.white,
                        borderRadius: 12,
                        margin: const EdgeInsets.all(16),
                        duration: const Duration(seconds: 3),
                        icon: const Icon(Icons.error, color: Colors.white),
                      );
                      return;
                    }

                    if (kDebugMode) {
                      print('   Calling submitParentSignup with lat: $lat, lng: $lng');
                    }

                    final ok = await pvm.submitParentSignup(
                      latitude: lat,
                      longitude: lng,
                    );

                    if (!context.mounted) return;

                    if (ok) {
                      // Success - navigate to login screen (parent needs to login)
                      if (!context.mounted) return;
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (context) => const LoginScreen()),
                        (route) => false,
                      );
                    } else if (pvm.errorMessage != null) {
                      Get.snackbar(
                        'Error',
                        pvm.errorMessage!,
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: AppColors.error,
                        colorText: Colors.white,
                        borderRadius: 12,
                        margin: const EdgeInsets.all(16),
                        duration: const Duration(seconds: 3),
                        icon: const Icon(Icons.error, color: Colors.white),
                      );
                    }
                  } else if (returnLocation) {
                    // Return location data for editing (e.g., tutor profile edit)
                    final lat = double.tryParse(vm.latitude);
                    final lng = double.tryParse(vm.longitude);

                    if (lat == null || lng == null) {
                      Get.snackbar(
                        'Invalid Input',
                        'Please enter valid coordinates.',
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: AppColors.error,
                        colorText: Colors.white,
                        borderRadius: 12,
                        margin: const EdgeInsets.all(16),
                        duration: const Duration(seconds: 3),
                        icon: const Icon(Icons.error, color: Colors.white),
                      );
                      return;
                    }

                    // Return location data
                    if (!context.mounted) return;
                    Navigator.of(context).pop({
                      'latitude': lat,
                      'longitude': lng,
                      'address': vm.selectedAddress,
                    });
                  } else {
                    // Simple parent signup (not from 4-step flow)
                    vm1.updateParentFullName(vm1.parentFullName);
                    vm1.updateParentEmail(vm1.parentEmail);
                    vm1.updateParentPassword(vm1.parentPassword);
                    vm1.updateParentPhone(vm1.parentPhone);
                    vm1.updateParentAddress(vm1.parentAddress);

                    final lat = double.tryParse(vm.latitude);
                    final lng = double.tryParse(vm.longitude);

                    // Update location in baseUser if available
                    if (lat != null && lng != null) {
                      // Note: Simple signup doesn't support location yet
                      // You may need to update AuthViewModel.registerParent to accept location
                    }

                    final ok = await vm1.registerParent();
                    if (!context.mounted) return;

                    if (ok) {
                      // Success - navigate to login screen (parent needs to login)
                      if (!context.mounted) return;
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (context) => const LoginScreen()),
                        (route) => false,
                      );
                    } else if (vm1.errorMessage != null) {
                      Get.snackbar(
                        'Error',
                        vm1.errorMessage!,
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: AppColors.error,
                        colorText: Colors.white,
                        borderRadius: 12,
                        margin: const EdgeInsets.all(16),
                        duration: const Duration(seconds: 3),
                        icon: const Icon(Icons.error, color: Colors.white),
                      );
                    }
                  }
                },
              ),

            ],
          ),
          ),
        ),
      ),
    );
  }
}
