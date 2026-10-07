import 'package:odaa_mobile/features/about/data/models/organization_info.dart';

abstract interface class AboutRepository {
  Future<OrganizationInfo> fetchOrganization();
}

class MockAboutRepository implements AboutRepository {
  @override
  Future<OrganizationInfo> fetchOrganization() async {
    await Future<void>.delayed(const Duration(milliseconds: 400));

    return const OrganizationInfo(
      missionEn:
          'Afoosha Odaa exists to support its members in times of loss, illness, and hardship through mutual aid — one household at a time.',
      missionOm:
          'Afoosha Odaan miseensota ishee yeroo du\'aa, dhukkubaa fi rakkinaa deeggaruuf walta\'iinsaan ni jiraata.',
      visionEn:
          'Every household stands in the shade of the Odaa — cared for, counted, and never alone.',
      visionOm:
          'Manni hundi gaaddisa Odaa jalatti dhaabbata — kunuunsa argata, lakkaa\'ama, gonkumaa kophaa hin hafu.',
      bylawsEn:
          '1. Every household contributes monthly as agreed at the annual meeting.\n'
          '2. Payments are made between the 27th of the month and the 2nd of the next month.\n'
          '3. Dues are settled in order. Newer months remain suspended until older ones are cleared.\n'
          '4. A member may request support for the loss of a spouse, child, parent, or sibling.\n'
          '5. All requests are reviewed by the committee and decided by majority.\n'
          '6. Minutes of every meeting are published to members.',
      bylawsOm:
          '1. Maatiin hundi ji\'aan gumaacha godha akkuma walga\'ii baraa irratti waliigale.\n'
          '2. Kaffaltiin guyyaa 27 fi guyyaa 2 gidduutti raawwatama.\n'
          '3. Kaffaltiin tartiiba isaan raawwatama. Ji\'oonni haaraan kan duraanii hin kaffalamne.\n'
          '4. Miseensi du\'aa haadha manaa, daa\'imaa, maatii, ykn obboleessaaf deeggarsa gaafachuu danda\'a.\n'
          '5. Gaaffiin hundi koreen ilaalamee sagalee baay\'een murteeffama.\n'
          '6. Galmeen walga\'ii hundi miseensotaaf maxxanfama.',
      committee: [
        CommitteeMember(
          name: 'Abebe Kebede',
          role: 'chairperson',
          phone: '+251911223344',
        ),
        CommitteeMember(
          name: 'Sara Tesfaye',
          role: 'secretary',
          phone: '+251922334455',
        ),
        CommitteeMember(
          name: 'Mulu Alemu',
          role: 'treasurer',
          phone: '+251933445566',
        ),
        CommitteeMember(
          name: 'Yonas Bekele',
          role: 'auditor',
          phone: '+251944556677',
        ),
      ],
    );
  }
}