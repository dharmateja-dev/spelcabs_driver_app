// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:driver/constant/collection_name.dart';
// import 'package:driver/constant/constant.dart';
// import 'package:driver/model/user_model.dart';
// import 'package:driver/themes/app_colors.dart';
// import 'package:driver/utils/app_logger.dart';
// import 'package:driver/utils/fire_store_utils.dart';
// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
//
// class UserView extends StatelessWidget {
//   final String? userId;
//   final String? amount;
//   final String? distance;
//   final String? distanceType;
//
//   const UserView({Key? key, this.userId, this.amount, this.distance, this.distanceType}) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     AppLogger.debug("UserView - userId: $userId");
//
//     // Early validation
//     if (userId == null || userId!.isEmpty) {
//       AppLogger.warning("UserView - userId is null or empty");
//       return _buildLoadingView();
//     }
//
//     return StreamBuilder<DocumentSnapshot>(
//       stream: FireStoreUtils.fireStore
//           .collection(CollectionName.users)
//           .doc(userId!)
//           .snapshots(),
//       builder: (context, snapshot) {
//         // Handle connection states
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           AppLogger.debug("UserView - Waiting for stream connection for userId: $userId");
//           return _buildLoadingView();
//         }
//
//         if (snapshot.hasError) {
//           AppLogger.error("UserView - Stream error for userId $userId: ${snapshot.error}");
//           final errorMessage = "Error fetching user data for ID $userId: ${snapshot.error}";
//           final snackBar = SnackBar(
//             content: Text(errorMessage),
//             duration: const Duration(seconds: 5),
//             backgroundColor: Colors.red, // Optional: customize background color for errors
//             // For longer messages, allow the SnackBar to be multiline
//             behavior: SnackBarBehavior.floating, // Or SnackBarBehavior.fixed based on your preference
//           );
//           // It's important to use a ScaffoldMessenger that is an ancestor of your current widget.
//           // If your UserView widget might not be under a Scaffold, consider finding it.
//           // However, in most typical Flutter app structures, a Scaffold is usually present.
//           WidgetsBinding.instance.addPostFrameCallback((_) {
//             ScaffoldMessenger.of(context).showSnackBar(snackBar);
//           });
//           return _buildErrorRetryView(context);
//         }
//
//         if (!snapshot.hasData) {
//           AppLogger.warning("UserView - No data received for userId: $userId");
//           return _buildLoadingView();
//         }
//
//         DocumentSnapshot doc = snapshot.data!;
//
//         if (!doc.exists) {
//           AppLogger.warning("UserView - Document does not exist for userId: $userId");
//           return _buildErrorRetryView(context);
//         }
//
//         try {
//           Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;
//
//           if (data == null || data.isEmpty) {
//             AppLogger.warning("UserView - Document data is null or empty for userId: $userId");
//             return _buildErrorRetryView(context);
//           }
//
//           UserModel userModel = UserModel.fromJson(data);
//
//           // Validate essential user data
//           if (userModel.fullName == null || userModel.fullName!.trim().isEmpty) {
//             AppLogger.warning("UserView - User fullName is null or empty for userId: $userId");
//             return _buildErrorRetryView(context);
//           }
//
//           AppLogger.info("UserView - Successfully loaded user: ${userModel.fullName} for userId: $userId");
//           return _buildUserView(userModel);
//
//         } catch (e, s) {
//           AppLogger.error("UserView - Error parsing user data for userId $userId: $e",
//               error: e, stackTrace: s);
//           return _buildErrorRetryView(context);
//         }
//       },
//     );
//   }
//
//   Widget _buildLoadingView() {
//     return Row(
//       crossAxisAlignment: CrossAxisAlignment.center,
//       children: [
//         ClipRRect(
//           borderRadius: const BorderRadius.all(Radius.circular(10)),
//           child: Container(
//             height: 50,
//             width: 50,
//             decoration: BoxDecoration(
//               color: Colors.grey[300],
//               borderRadius: BorderRadius.circular(10),
//             ),
//             child: const Center(
//               child: SizedBox(
//                 height: 20,
//                 width: 20,
//                 child: CircularProgressIndicator(strokeWidth: 2),
//               ),
//             ),
//           ),
//         ),
//         const SizedBox(width: 10),
//         Expanded(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Container(
//                 height: 16,
//                 width: 120,
//                 decoration: BoxDecoration(
//                   color: Colors.grey[300],
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//               ),
//               const SizedBox(height: 8),
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Text(Constant.amountShow(amount: amount?.toString() ?? "0"),
//                       style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
//                   Row(
//                     children: [
//                       const Icon(Icons.location_on, size: 18),
//                       const SizedBox(width: 5),
//                       Text("${_safeParseDistance()} ${distanceType ?? 'km'}",
//                           style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
//                     ],
//                   ),
//                   Row(
//                     children: [
//                       const Icon(Icons.star, size: 22, color: AppColors.ratingColour),
//                       const SizedBox(width: 5),
//                       Text(Constant.calculateReview(reviewCount: "0.0", reviewSum: "0.0"),
//                           style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
//                     ],
//                   ),
//                 ],
//               )
//             ],
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildErrorRetryView(BuildContext context) {
//     return Row(
//       crossAxisAlignment: CrossAxisAlignment.center,
//       children: [
//         ClipRRect(
//           borderRadius: const BorderRadius.all(Radius.circular(10)),
//           child: CachedNetworkImage(
//             height: 50,
//             width: 50,
//             imageUrl: Constant.userPlaceHolder,
//             fit: BoxFit.cover,
//             placeholder: (context, url) => Constant.loader(context),
//             errorWidget: (context, url, error) => Container(
//               height: 50,
//               width: 50,
//               decoration: BoxDecoration(
//                 color: Colors.grey[400],
//                 borderRadius: BorderRadius.circular(10),
//               ),
//               child: const Icon(Icons.person, color: Colors.white),
//             ),
//           ),
//         ),
//         const SizedBox(width: 10),
//         Expanded(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Row(
//                 children: [
//                   Text("User unavailable",
//                       style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.grey[600])),
//                   const SizedBox(width: 8),
//                   InkWell(
//                     onTap: () {
//                       // Force rebuild by creating a new widget
//                       AppLogger.debug("UserView - Retry tapped for userId: $userId");
//                       (context as Element).markNeedsBuild();
//                     },
//                     child: Container(
//                       padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
//                       decoration: BoxDecoration(
//                         color: AppColors.primary.withOpacity(0.1),
//                         borderRadius: BorderRadius.circular(4),
//                       ),
//                       child: Text("Retry",
//                           style: GoogleFonts.poppins(fontSize: 10, color: AppColors.primary)),
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 4),
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Text(Constant.amountShow(amount: amount?.toString() ?? "0"),
//                       style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
//                   Row(
//                     children: [
//                       const Icon(Icons.location_on, size: 18),
//                       const SizedBox(width: 5),
//                       Text("${_safeParseDistance()} ${distanceType ?? 'km'}",
//                           style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
//                     ],
//                   ),
//                   Row(
//                     children: [
//                       const Icon(Icons.star, size: 22, color: AppColors.ratingColour),
//                       const SizedBox(width: 5),
//                       Text(Constant.calculateReview(reviewCount: "0.0", reviewSum: "0.0"),
//                           style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
//                     ],
//                   ),
//                 ],
//               )
//             ],
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildUserView(UserModel userModel) {
//     return Row(
//       crossAxisAlignment: CrossAxisAlignment.center,
//       children: [
//         ClipRRect(
//           borderRadius: const BorderRadius.all(Radius.circular(10)),
//           child: CachedNetworkImage(
//             height: 50,
//             width: 50,
//             imageUrl: userModel.profilePic?.toString() ?? Constant.userPlaceHolder,
//             fit: BoxFit.cover,
//             placeholder: (context, url) => Container(
//               height: 50,
//               width: 50,
//               decoration: BoxDecoration(
//                 color: Colors.grey[300],
//                 borderRadius: BorderRadius.circular(10),
//               ),
//               child: const Center(
//                 child: SizedBox(
//                   height: 20,
//                   width: 20,
//                   child: CircularProgressIndicator(strokeWidth: 2),
//                 ),
//               ),
//             ),
//             errorWidget: (context, url, error) => Container(
//               height: 50,
//               width: 50,
//               decoration: BoxDecoration(
//                 color: Colors.grey[400],
//                 borderRadius: BorderRadius.circular(10),
//               ),
//               child: const Icon(Icons.person, color: Colors.white),
//             ),
//           ),
//         ),
//         const SizedBox(width: 10),
//         Expanded(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(userModel.fullName!.trim(),
//                   style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Text(Constant.amountShow(amount: amount?.toString() ?? "0"),
//                       style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
//                   Row(
//                     children: [
//                       const Icon(Icons.location_on, size: 18),
//                       const SizedBox(width: 5),
//                       Text("${_safeParseDistance()} ${distanceType ?? 'km'}",
//                           style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
//                     ],
//                   ),
//                   Row(
//                     children: [
//                       const Icon(Icons.star, size: 22, color: AppColors.ratingColour),
//                       const SizedBox(width: 5),
//                       Text(Constant.calculateReview(
//                           reviewCount: userModel.reviewsCount ?? "0.0",
//                           reviewSum: userModel.reviewsSum ?? "0.0"),
//                           style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
//                     ],
//                   ),
//                 ],
//               )
//             ],
//           ),
//         ),
//       ],
//     );
//   }
//
//   String _safeParseDistance() {
//     try {
//       if (distance == null || distance!.isEmpty) return "0.0";
//       double parsedDistance = double.parse(distance!);
//       return parsedDistance.toStringAsFixed(Constant.currencyModel?.decimalDigits ?? 2);
//     } catch (e) {
//       AppLogger.warning("UserView - Error parsing distance '$distance': $e");
//       return "0.0";
//     }
//   }
// }
import 'dart:async';
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:driver/constant/collection_name.dart';
import 'package:driver/constant/constant.dart';
import 'package:driver/model/user_model.dart';
import 'package:driver/themes/app_colors.dart';
import 'package:driver/utils/app_logger.dart';
import 'package:driver/utils/fire_store_utils.dart';
import 'package:driver/utils/preferences.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class UserView extends StatefulWidget {
  final String? userId;
  final String? amount;
  final String? distance;
  final String? distanceType;

  const UserView(
      {super.key, this.userId, this.amount, this.distance, this.distanceType});

  @override
  State<UserView> createState() => _UserViewState();
}

class _UserViewState extends State<UserView> {
  final int _maxRetries = 3;
  final Map<String, UserModel> _memoryCache = {};
  Stream<UserModel?>? _userStream;
  StreamController<UserModel?>? _streamController;
  int _retryCount = 0;
  Timer? _retryTimer;

  @override
  void initState() {
    super.initState();
    _initUserStream();
  }

  @override
  void didUpdateWidget(covariant UserView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId) {
      _initUserStream();
    }
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    _streamController?.close();
    super.dispose();
  }

  void _initUserStream() {
    _retryTimer?.cancel();
    _retryCount = 0;

    if (widget.userId == null || widget.userId!.isEmpty) {
      AppLogger.warning("UserView - userId is null or empty");
      return;
    }

    _userStream = _createUserStream(widget.userId!);
    setState(() {});
  }

  Stream<UserModel?> _createUserStream(String userId) {
    final StreamController<UserModel?> controller = StreamController();
    _streamController = controller;
    UserModel? cachedUser;

    // 1. Check memory cache
    if (_memoryCache.containsKey(userId)) {
      cachedUser = _memoryCache[userId];
      controller.add(cachedUser);
      AppLogger.info("UserView - Using memory cache for $userId");
    }
    // 2. Check persistent cache
    else {
      cachedUser = _getCachedUser(userId);
      if (cachedUser != null) {
        _memoryCache[userId] = cachedUser;
        controller.add(cachedUser);
        AppLogger.info("UserView - Using persistent cache for $userId");
      }
    }

    // 3. Create Firestore stream with retry logic
    late void Function() subscribe;
    StreamSubscription<DocumentSnapshot>? firestoreSub;

    subscribe = () {
      firestoreSub?.cancel();
      firestoreSub = FirebaseFirestore.instance
          .collection(CollectionName.users)
          .doc(userId)
          .snapshots()
          .listen(
        (snapshot) {
          _retryCount = 0;
          if (snapshot.exists) {
            try {
              final user = UserModel.fromJson(snapshot.data()!);
              _memoryCache[userId] = user;
              _saveUserToCache(userId, user);
              controller.add(user);
              AppLogger.info(
                  "UserView - Updated user from Firestore for $userId");
            } catch (e, s) {
              AppLogger.error("UserView - Parsing error for $userId: $e",
                  error: e, stackTrace: s);
              controller.add(cachedUser); // Fallback to cached version
            }
          } else {
            controller.add(cachedUser); // Fallback to cached version
          }
        },
        onError: (error) {
          AppLogger.error("UserView - Stream error for $userId: $error");
          firestoreSub?.cancel();

          // Retry logic
          if (_retryCount < _maxRetries) {
            _retryCount++;
            AppLogger.info(
                "UserView - Retrying ($_retryCount/$_maxRetries) for $userId");

            _retryTimer = Timer(const Duration(seconds: 1), () {
              subscribe();
            });
          } else {
            controller.addError("Max retries reached for $userId");
          }
        },
      );
    };

    // Start the initial subscription
    subscribe();

    controller.onCancel = () {
      firestoreSub?.cancel();
      _retryTimer?.cancel();
    };

    return controller.stream;
  }

  UserModel? _getCachedUser(String userId) {
    try {
      // Safety check for initialized Preferences
      if (!Preferences.pref.containsKey(
          "")) {} // This is just a dummy access to check late init if needed, but safer to check if initialized if we had a flag.
      // Since pref is 'late', we catch the error if it's not ready.

      final cachedData = Preferences.getString("cached_user_$userId");
      if (cachedData.isNotEmpty) {
        return UserModel.fromJson(jsonDecode(cachedData));
      }
    } catch (e) {
      // This catches LateInitializationError and other read errors
      AppLogger.error("UserView - Cache read error for $userId: $e");
    }
    return null;
  }

  void _saveUserToCache(String userId, UserModel user) {
    try {
      // Skip if preferences not ready
      if (user.id == null) return;

      final String jsonStr = jsonEncode(user.toJson());
      Preferences.setString("cached_user_$userId", jsonStr);
    } catch (e) {
      // This catches LateInitializationError and encoding errors
      AppLogger.error("UserView - Cache write error for $userId: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.userId == null || widget.userId!.isEmpty) {
      AppLogger.warning("UserView - userId is null or empty");
      return _buildLoadingView();
    }

    if (_userStream == null) {
      return _buildLoadingView();
    }

    return StreamBuilder<UserModel?>(
      stream: _userStream,
      builder: (context, snapshot) {
        // Show loading state while waiting for first data
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData &&
            !snapshot.hasError) {
          return _buildLoadingView();
        }

        // Handle error state
        if (snapshot.hasError) {
          AppLogger.error("UserView - StreamBuilder error: ${snapshot.error}");
          return _buildErrorRetryView(context);
        }

        // Handle case where user doesn't exist
        if (snapshot.data == null) {
          AppLogger.warning(
              "UserView - User data is null for ${widget.userId}");
          return _buildErrorRetryView(context);
        }

        // Show user data
        return _buildUserView(snapshot.data!);
      },
    );
  }

  Widget _buildLoadingView() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(10)),
          child: Container(
            height: 50,
            width: 50,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(
              child: SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 16,
                width: 120,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                      Constant.amountShow(
                          amount: widget.amount?.toString() ?? "0"),
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 18),
                      const SizedBox(width: 5),
                      Text(
                          "${_safeParseDistance()} ${widget.distanceType ?? 'km'}",
                          style:
                              GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(Icons.star,
                          size: 22, color: AppColors.ratingColour),
                      const SizedBox(width: 5),
                      Text(
                          Constant.calculateReview(
                              reviewCount: "0.0", reviewSum: "0.0"),
                          style:
                              GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                    ],
                  ),
                ],
              )
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildErrorRetryView(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(10)),
          child: CachedNetworkImage(
            height: 50,
            width: 50,
            imageUrl: Constant.userPlaceHolder,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              height: 50,
              width: 50,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
            errorWidget: (context, url, error) => Container(
              height: 50,
              width: 50,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.person, color: Colors.white),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text("User unavailable",
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[600])),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () {
                      AppLogger.info("UserView - Manual retry triggered");
                      _initUserStream();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text("Retry",
                          style: GoogleFonts.poppins(
                              fontSize: 10, color: AppColors.primary)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                      Constant.amountShow(
                          amount: widget.amount?.toString() ?? "0"),
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 18),
                      const SizedBox(width: 5),
                      Text(
                          "${_safeParseDistance()} ${widget.distanceType ?? 'km'}",
                          style:
                              GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(Icons.star,
                          size: 22, color: AppColors.ratingColour),
                      const SizedBox(width: 5),
                      Text(
                          Constant.calculateReview(
                              reviewCount: "0.0", reviewSum: "0.0"),
                          style:
                              GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                    ],
                  ),
                ],
              )
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUserView(UserModel userModel) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(10)),
          child: CachedNetworkImage(
            height: 50,
            width: 50,
            imageUrl:
                userModel.profilePic?.toString() ?? Constant.userPlaceHolder,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              height: 50,
              width: 50,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
            errorWidget: (context, url, error) => Container(
              height: 50,
              width: 50,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.person, color: Colors.white),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(userModel.fullName?.trim() ?? "Unknown User",
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                      Constant.amountShow(
                          amount: widget.amount?.toString() ?? "0"),
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 18),
                      const SizedBox(width: 5),
                      Text(
                          "${_safeParseDistance()} ${widget.distanceType ?? 'km'}",
                          style:
                              GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(Icons.star,
                          size: 22, color: AppColors.ratingColour),
                      const SizedBox(width: 5),
                      Text(
                          Constant.calculateReview(
                              reviewCount: userModel.reviewsCount ?? "0.0",
                              reviewSum: userModel.reviewsSum ?? "0.0"),
                          style:
                              GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                    ],
                  ),
                ],
              )
            ],
          ),
        ),
      ],
    );
  }

  String _safeParseDistance() {
    try {
      if (widget.distance == null || widget.distance!.isEmpty) return "0.0";
      double parsedDistance = double.parse(widget.distance!);
      return parsedDistance
          .toStringAsFixed(Constant.currencyModel?.decimalDigits ?? 2);
    } catch (e) {
      AppLogger.warning("UserView - Error parsing distance: $e");
      return "0.0";
    }
  }
}
