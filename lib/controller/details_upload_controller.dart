import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:driver/constant/constant.dart';
import 'package:driver/constant/show_toast_dialog.dart';
import 'package:driver/model/document_model.dart';
import 'package:driver/model/driver_document_model.dart';
import 'package:driver/model/language_title.dart';
import 'package:driver/utils/fire_store_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class DetailsUploadController extends GetxController {
  Rx<DocumentModel> documentModel = DocumentModel().obs;

  Rx<TextEditingController> documentNumberController =
      TextEditingController().obs;
  Rx<TextEditingController> expireAtController = TextEditingController().obs;
  Rx<DateTime?> selectedDate = DateTime.now().obs;

  RxString frontImage = "".obs;
  RxString backImage = "".obs;

  RxString documentNumberError = "".obs;

  RxBool isLoading = true.obs;

  bool validateDocument() {
    String docNumber = documentNumberController.value.text.trim();
    String docId = documentModel.value.id?.toLowerCase() ?? "";

    // Get English title for robust checking
    String docTitle = "";
    if (documentModel.value.title != null) {
      try {
        var enTitleObj = documentModel.value.title!.firstWhere(
            (element) => element.type == "en",
            orElse: () => LanguageTitle(title: ""));
        docTitle = enTitleObj.title?.toLowerCase() ?? "";
      } catch (e) {
        docTitle = "";
      }
    }

    bool isDL = docId.contains("driving") ||
        docId.contains("licence") ||
        docId.contains("license") ||
        docId.contains("dl") ||
        docTitle.contains("driving") ||
        docTitle.contains("licence") ||
        docTitle.contains("license") ||
        docTitle.contains("driver license");

    if (docNumber.isEmpty) {
      documentNumberError.value = "Please enter document number";
      return false;
    }

    if (isDL) {
      // Indian Driving License Regex
      // Matches: SS-RR-YYYY-NNNNNNN or SSRRYYYYNNNNNNN
      // SS: State Code (2 chars)
      // RR: RTO Code (2 digits)
      // YYYY: Year (19xx or 20xx)
      // NNNNNNN: 7 digits
      // Total 15 chars (if no separators) or 16 (with space/dash)
      // We'll strip separators for validation
      String cleanNumber = docNumber.replaceAll(RegExp(r'[\s-]'), '');

      // Strict regex for 15 or 16-character Indian DL
      // ^[A-Z]{2} : State Code
      // [A-Z0-9]{2,3} : RTO Code (2 or 3 alphanumeric)
      // (19|20)[0-9]{2} : Year 1900-2099
      // [0-9]{7} : 7 digit unique number
      RegExp dlRegex =
          RegExp(r"^[A-Z]{2}[A-Z0-9]{2,3}(19|20)[0-9]{2}[0-9]{7}$");

      if (!dlRegex.hasMatch(cleanNumber.toUpperCase())) {
        documentNumberError.value = "Invalid format. Use SS-RR-YYYY-NNNNNNN";
        return false;
      }
    } else if (docId.contains("pan") || docTitle.contains("pan")) {
      if (!RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]{1}$')
          .hasMatch(docNumber.toUpperCase())) {
        documentNumberError.value = "Invalid PAN format (ABCDE1234F)";
        return false;
      }
    } else if (docId.contains("aadhaar") ||
        docTitle.contains("aadhaar") ||
        docTitle.contains("adhaar")) {
      if (!RegExp(r'^\d{12}$').hasMatch(docNumber)) {
        documentNumberError.value = "Invalid Aadhaar number (12 digits)";
        return false;
      }
    }

    documentNumberError.value = "";
    return true;
  }

  @override
  void onInit() {
    // TODO: implement onInit
    getArgument();
    super.onInit();
  }

  getArgument() async {
    dynamic argumentData = Get.arguments;
    if (argumentData != null) {
      documentModel.value = argumentData['documentModel'];
    }
    getDocument();
    update();
  }

  Rx<Documents> documents = Documents().obs;

  getDocument() async {
    await FireStoreUtils.getDocumentOfDriver().then((value) {
      isLoading.value = false;
      if (value != null) {
        var contain = value.documents!
            .where((element) => element.documentId == documentModel.value.id);
        if (contain.isNotEmpty) {
          documents.value = value.documents!.firstWhere((itemToCheck) =>
              itemToCheck.documentId == documentModel.value.id);

          documentNumberController.value.text = documents.value.documentNumber!;
          frontImage.value = documents.value.frontImage!;
          backImage.value = documents.value.backImage!;
          if (documents.value.expireAt != null) {
            selectedDate.value = documents.value.expireAt!.toDate();
            expireAtController.value.text =
                DateFormat("dd-MM-yyyy").format(selectedDate.value!);
          }
        }
      }
    });
  }

  final ImagePicker _imagePicker = ImagePicker();

  Future pickFile({required ImageSource source, required String type}) async {
    try {
      XFile? image = await _imagePicker.pickImage(source: source);
      if (image == null) return;

      // 1. Validate File Format (Extension)
      if (!isValidFileType(image.path)) {
        ShowToastDialog.showToast(
            "Invalid file format. Please upload JPG, JPEG, or PNG.");
        return;
      }

      // 2. Validate File Size (Max 5MB)
      if (!await isValidFileSize(image.path)) {
        ShowToastDialog.showToast(
            "File size too large. Max allowed size is 5MB.");
        return;
      }

      Get.back();

      if (type == "front") {
        frontImage.value = image.path;
      } else {
        backImage.value = image.path;
      }
    } on PlatformException catch (e) {
      ShowToastDialog.showToast("Failed to Pick : \n $e");
    }
  }

  bool isValidFileType(String path) {
    String extension = path.split('.').last.toLowerCase();
    return ['jpg', 'jpeg', 'png'].contains(extension);
  }

  Future<bool> isValidFileSize(String path) async {
    File file = File(path);
    int sizeInBytes = await file.length();
    double sizeInMb = sizeInBytes / (1024 * 1024);
    return sizeInMb <= 5;
  }

  uploadDocument() async {
    String frontImageFileName = File(frontImage.value).path.split('/').last;
    String backImageFileName = File(backImage.value).path.split('/').last;

    if (frontImage.value.isNotEmpty &&
        Constant().hasValidUrl(frontImage.value) == false) {
      frontImage.value = await Constant.uploadUserImageToFireStorage(
          File(frontImage.value),
          "driverDocument/${FireStoreUtils.getCurrentUid()}",
          frontImageFileName);
    }

    if (backImage.value.isNotEmpty &&
        Constant().hasValidUrl(backImage.value) == false) {
      backImage.value = await Constant.uploadUserImageToFireStorage(
          File(backImage.value),
          "driverDocument/${FireStoreUtils.getCurrentUid()}",
          backImageFileName);
    }
    documents.value.frontImage = frontImage.value;
    documents.value.documentId = documentModel.value.id;
    documents.value.documentNumber = documentNumberController.value.text;
    documents.value.backImage = backImage.value;
    documents.value.verified = false;
    if (documentModel.value.expireAt == true) {
      documents.value.expireAt = Timestamp.fromDate(selectedDate.value!);
    }

    await FireStoreUtils.uploadDriverDocument(documents.value).then((value) {
      if (value) {
        ShowToastDialog.closeLoader();
        ShowToastDialog.showToast("Document upload successfully");

        Get.back();
      }
    });
  }
}
