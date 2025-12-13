import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_primary_button.dart';
import '../../core/widgets/app_text.dart';
import '../../core/widgets/app_textfield.dart';
import '../../parent_viewmodels/auth_vm.dart';
import '../../parent_viewmodels/location_vm.dart';
import '../../parent_viewmodels/parent_signup_vm.dart';


class LocationSelectionScreen extends StatelessWidget {
  /// Parent flow se aa raha ho? → true
  /// Tutor ka standalone location step ho? → false
  final bool showStepIndicator;

  /// Parent flow me kaunsa step (0-based index)
  /// e.g. agar yeh 4th step hai to 3
  final int? stepIndex;

  /// Button text (default: "Save")
  final String buttonLabel;

  const LocationSelectionScreen({
    super.key,
    this.showStepIndicator = false,
    this.stepIndex,
    this.buttonLabel = 'Save',
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LocationViewModel(),
      child: _LocationSelectionView(
        showStepIndicator: showStepIndicator,
        stepIndex: stepIndex,
        buttonLabel: buttonLabel,
      ),
    );
  }
}

class _LocationSelectionView extends StatelessWidget {
  final bool showStepIndicator;
  final int? stepIndex;
  final String buttonLabel;

  const _LocationSelectionView({
    required this.showStepIndicator,
    required this.stepIndex,
    required this.buttonLabel,
  });

  /// Build markers for the map
  Set<Marker> _buildMarkers(LocationViewModel vm) {
    if (vm.latitude.isEmpty || vm.longitude.isEmpty) {
      return {};
    }

    final lat = double.tryParse(vm.latitude);
    final lng = double.tryParse(vm.longitude);

    if (lat == null || lng == null) {
      return {};
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

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<LocationViewModel>();
    final theme = Theme.of(context);
    final vm1 = context.watch<AuthViewModel>();
    final ParentSignupViewModel? pvm =
        showStepIndicator ? context.watch<ParentSignupViewModel>() : null;

    return Scaffold(
      backgroundColor: AppColors.background,
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
              TextField(
                controller: TextEditingController(text: vm.searchQuery),
                onChanged: (value) {
                  vm.updateSearchQuery(value);
                },
                onSubmitted: (value) {
                  if (value.trim().isNotEmpty) {
                    vm.searchAddress(value);
                  }
                },
                decoration: InputDecoration(
                  hintText: 'Search for a city or address',
                  filled: true,
                  fillColor: AppColors.lightBackground,
                  prefixIcon:
                  const Icon(Icons.search, color: AppColors.iconGrey),
                  suffixIcon: vm.searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: AppColors.iconGrey),
                          onPressed: () {
                            vm.updateSearchQuery('');
                          },
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 2,
                    ),
                  ),
                ),
              ),
              if (vm.errorMessage != null) ...[
                const SizedBox(height: 8),
                AppText(
                  vm.errorMessage!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.error,
                  ),
                ),
              ],
              const SizedBox(height: 16),

              // Use my current location
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
                      color: AppColors.primary.withOpacity(0.3),
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
              const SizedBox(height: 16),

              // Google Map
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  height: 260,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.2),
                      width: 2,
                    ),
                  ),
                  child: Stack(
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
                        zoomControlsEnabled: false,
                        mapToolbarEnabled: false,
                        markers: _buildMarkers(vm),
                      ),
                      // Center indicator
                      Center(
                        child: Icon(
                          Icons.location_on,
                          color: AppColors.primary,
                          size: 40,
                        ),
                      ),
                    ],
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

              // ⭐ Coordinates fields (Latitude + Longitude)
              AppText(
                'Coordinates',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      label: 'Latitude',
                      hintText: 'e.g. 37.7749',
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      ),
                      onChanged: vm.updateLatitude,
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppTextField(
                      label: 'Longitude',
                      hintText: 'e.g. -122.4194',
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      ),
                      onChanged: vm.updateLongitude,
                      textInputAction: TextInputAction.done,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              AppPrimaryButton(
                label: buttonLabel,
                isLoading: showStepIndicator
                    ? (pvm?.isLoading ?? false)
                    : vm1.isLoading,
                isDisabled: showStepIndicator
                    ? !(vm.canSave && (pvm?.isStep3Valid ?? false))
                    : !vm1.canSubmitParentSignup,
                onPressed: () async {
                  if (showStepIndicator && pvm != null) {
                    // Parent 4-step flow: Use ParentSignupViewModel
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

                    final ok = await pvm.submitParentSignup(
                      latitude: lat,
                      longitude: lng,
                    );

                    if (!context.mounted) return;

                    if (ok) {
                      // Success - navigate to home/dashboard
                      Navigator.of(context).pushNamedAndRemoveUntil(
                        '/parent-home',
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
                      // Success - navigate to home
                      Navigator.of(context).pushNamedAndRemoveUntil(
                        '/parent-home',
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
