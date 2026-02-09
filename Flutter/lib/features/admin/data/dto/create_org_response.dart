import 'organization_out.dart';

class CreateOrganizationResponse {
  final OrganizationOut organization;

  CreateOrganizationResponse({required this.organization});

  factory CreateOrganizationResponse.fromJson(Map<String, dynamic> json) {
    final orgJson = (json["organization"] as Map?)?.cast<String, dynamic>() ?? {};
    return CreateOrganizationResponse(
      organization: OrganizationOut.fromJson(orgJson),
    );
  }
}
