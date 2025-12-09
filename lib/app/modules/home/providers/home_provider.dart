import 'package:getx_project/app/api_providers.dart';
import 'package:getx_project/app/models/dashboard_model.dart';

class HomeProvider extends ApiProvider {
  // @override
  // void onInit() {
  //   httpClient.baseUrl = 'https://dummyjson.com/';
  // }

 Future<DashboardModel> getDashboard({required int year}) async {
  final response = await get('/dashboard-inventory', 
    query: {
      'year': year.toString(),
    },);
  final resBody = response.body;

  if (response.statusCode == 200 && resBody != null && resBody['success'] == true) {
    return DashboardModel.fromJson(resBody['data']);
  } else {
    throw Exception('Failed to load dashboard: ${response.statusText}');
  }
}

}