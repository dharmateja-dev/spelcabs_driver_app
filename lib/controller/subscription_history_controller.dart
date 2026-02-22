import 'package:driver/model/subscription_history.dart';
import 'package:driver/utils/fire_store_utils.dart';
import 'package:get/get.dart';

class SubscriptionHistoryController extends GetxController {
  RxBool isLoading = true.obs;
  RxList<SubscriptionHistoryModel> subscriptionHistoryList =
      <SubscriptionHistoryModel>[].obs;

  @override
  void onInit() {
    getAllSubscriptionList();
    super.onInit();
  }

  Future<void> getAllSubscriptionList() async {
    isLoading.value = true;
    subscriptionHistoryList.value =
        await FireStoreUtils.getSubscriptionHistory();
    isLoading.value = false;
  }
}
/*******************************************************************************************
* Copyright (c) 2025 Movenetics Digital. All rights reserved.
*
* This software and associated documentation files are the property of 
* Movenetics Digital. Unauthorized copying, modification, distribution, or use of this 
* Software, via any medium, is strictly prohibited without prior written permission.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, 
* INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR 
* PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE 
* LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT 
* OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR 
* OTHER DEALINGS IN THE SOFTWARE.
*
* Company: Movenetics Digital
* Author: Aman Bhandari 
*******************************************************************************************/
