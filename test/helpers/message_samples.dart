import 'package:battle_protocol/battle_protocol.dart';

/// One sample of every client message, by its JSON type, with realistic
/// values. The committed encodings of these samples freeze the messages of
/// version 1 (`test/fixtures/v1/`).
final sampleClientMessages = <String, ClientMessage>{
  'sign_in': const SignIn(
    battleId: 'b-0f3e91c2',
    kind: CredentialKind.jwt,
    credential: 'eyJhbGciOiJIUzI1NiJ9.eyJ1c2VySWQiOiJhLTY1MzEifQ.c2lnbmF0dXJl',
  ),
  'sign_in_api_key': const SignIn(
    battleId: 'b-0f3e91c2',
    kind: CredentialKind.apiKey,
    credential: 'btk_q2YvW8n0x1Hc5lZtR3pK7sD9fG4jB6mN2aE8uV0iO1y',
  ),
  'send_command': SendCommand(
    requestId: 4096,
    command: Command(
      sender: const Sender(accountId: 'a-6531d2f0b8c4', sectionId: 's-1c9e'),
      sentAt: const Duration(hours: 5, milliseconds: 120),
      order: Move(unitId: 'u-jeep-7', to: Position.metres(4230.5, 25120, 41)),
    ),
  ),
  'resync_request': const ResyncRequest(),
  'heartbeat': const Heartbeat(),
};

const _ap = ApView(
  value: 17.25,
  at: Duration(hours: 5, seconds: 3),
  perHour: 1,
  max: 30,
);

/// An own unit of the sample section, with its private state.
UnitView _own(int index) => UnitView(
  unitId: 'u-rifle-$index',
  unitType: index == 0 ? 'commander' : 'soldier',
  sectionId: 's-1c9e',
  team: 'team-red',
  hp: 100 - index * 2.5,
  maxHp: 100,
  position: Position.metres(4210.5 + index * 20, 25110.25 + index * 3, 42.5),
  weapon: index < 3 ? 'machine_gun' : 'rifle',
  private: UnitPrivate(
    place: UnitPlace.deployed,
    ap: ApView(
      value: 30 - index.toDouble(),
      at: Duration(hours: 5, seconds: index),
      perHour: 1,
      max: 30,
    ),
    morale: 0.8,
    rounds: 10 - index % 10,
    xpEarned: 120.5 + index,
    xpUnspent: 20,
  ),
);

/// Ten moving vehicles in one tick.
final List<UnitPosition> _tenVehicles = [
  for (var i = 0; i < 10; i++)
    UnitPosition(
      i.isEven ? 'u-jeep-$i' : 'u-tank-$i',
      Position.metres(4800.37 + i * 35.5, 25600.12 - i * 12.25, 38.4),
    ),
];

const _section = SectionPrivate(
  money: 1250,
  xp: 340.5,
  storedWeapons: ['anti_tank', 'machine_gun'],
);

/// One sample of every host message, by its JSON type, with realistic
/// values; the samples whose sizes `stack/03` estimates are named after
/// them.
final sampleHostMessages = <String, HostMessage>{
  'sign_in_accepted': const SignInAccepted(
    accountId: 'a-6531d2f0b8c4',
    sectionId: 's-1c9e',
    team: 'team-red',
    battleTime: Duration(hours: 5, milliseconds: 250),
  ),
  'sign_in_refused': const SignInRefused(SignInRefusal.noSection),
  'command_accepted': const CommandAccepted(requestId: 4096, seq: 7311),
  'command_refused': const CommandRefused(
    requestId: 4097,
    reason: 'target_not_seen',
  ),
  'section_view': SectionView(
    at: const Duration(hours: 5, seconds: 3),
    section: const SectionPrivate(
      money: 1250,
      xp: 340.5,
      lockedUntil: Duration(hours: 6),
      storedWeapons: ['anti_tank'],
      prisoners: [JoinedUnit(unitId: 'u-enemy-3', unitType: 'scout')],
      offers: [
        OfferPosted(
          offerId: 1024,
          captorSectionId: 's-1c9e',
          ownerSectionId: 's-8f2a',
          released: ['u-enemy-3'],
          wanted: ['u-rifle-9'],
          price: 0,
        ),
      ],
    ),
    units: [
      _own(1),
      const UnitView(
        unitId: 'u-truck-2',
        unitType: 'truck',
        sectionId: 's-1c9e',
        team: 'team-red',
        hp: 200,
        maxHp: 200,
        private: UnitPrivate(
          place: UnitPlace.stored,
          ap: _ap,
          morale: 1,
          rounds: 0,
          xpEarned: 0,
          xpUnspent: 0,
        ),
      ),
      UnitView(
        unitId: 'u-rifle-4',
        unitType: 'soldier',
        sectionId: 's-1c9e',
        team: 'team-red',
        hp: 64,
        maxHp: 100,
        position: Position.metres(4230.5, 25120, 41),
        weapon: 'rifle',
        private: const UnitPrivate(
          place: UnitPlace.carried,
          ap: _ap,
          morale: 0.55,
          rounds: 4,
          xpEarned: 75,
          xpUnspent: 5,
          transportId: 'u-jeep-7',
          movingUntil: Duration(hours: 5, seconds: 40),
          busyUntil: Duration(hours: 5, seconds: 6),
          observingUntil: Duration(hours: 5, minutes: 30),
        ),
      ),
      UnitView(
        unitId: 'u-heli-2',
        unitType: 'helicopter',
        sectionId: 's-8f2a',
        team: 'team-blue',
        hp: 310,
        maxHp: 400,
        position: Position.metres(4600, 25900.5, 120),
        flying: true,
        weapon: 'machine_gun',
      ),
    ],
    hqs: [
      HqView(
        team: 'team-red',
        position: Position.metres(4990, 1490, 31),
        hp: 1000,
        maxHp: 1000,
        ap: _ap,
      ),
      HqView(
        team: 'team-blue',
        position: Position.metres(5000, 48500, 12.5),
        hp: 640,
        maxHp: 1000,
      ),
    ],
    relics: [
      RelicView(
        relicId: 'relic-3',
        position: Position.metres(4750, 18300, 22),
        owner: 'team-red',
      ),
      RelicView(relicId: 'relic-4', position: Position.metres(3000, 23500, 9)),
    ],
    hold: const HoldView(
      team: 'team-red',
      since: Duration(hours: 4),
      winsAt: Duration(hours: 28),
    ),
    world: [
      const StructureBuilt(
        siteId: 'site-12',
        structure: 'wall',
        cells: [Cell(421, 2511), Cell(422, 2511)],
      ),
      const ObjectDamaged(
        object: 'building',
        cells: [Cell(430, 2520)],
        hp: 220,
      ),
      const ObjectDestroyed(object: 'tree', cells: [Cell(425, 2512)]),
      CraterDug(at: Position.metres(4260, 25150, 40), radiusM: 8, depthM: 1.5),
    ],
  ),
  'tick_update': TickUpdate(
    at: const Duration(hours: 5, seconds: 4, milliseconds: 200),
    moved: [_tenVehicles.first],
    appeared: [
      UnitView(
        unitId: 'u-enemy-6',
        unitType: 'tank',
        sectionId: 's-8f2a',
        team: 'team-blue',
        hp: 600,
        maxHp: 600,
        position: Position.metres(4900, 25800, 37),
        weapon: 'anti_tank',
      ),
    ],
    gone: const ['u-heli-2'],
    events: const [
      MoveStarted(
        moverId: 'u-jeep-0',
        arrivesAt: Duration(hours: 5, seconds: 30),
      ),
    ],
    bursts: const [
      Burst(
        attackerId: 'u-rifle-1',
        sectionId: 's-1c9e',
        weapon: 'machine_gun',
        shots: 8,
        hits: 3,
        impacts: [
          Impact(
            targetId: 'u-enemy-6',
            targetType: 'tank',
            damage: 7.5,
            friendly: false,
            result: ImpactResult.damaged,
          ),
        ],
      ),
    ],
    unseenHits: const [
      UnseenHit(
        targetId: 'u-rifle-3',
        damage: 40,
        result: ImpactResult.damaged,
      ),
    ],
    fired: const [
      Fired(
        attackerId: 'u-enemy-6',
        sectionId: 's-8f2a',
        weapon: 'anti_tank',
        shots: 2,
        impacts: [
          Impact(
            targetId: 'u-rifle-1',
            targetType: 'soldier',
            damage: 30,
            friendly: false,
            result: ImpactResult.damaged,
          ),
        ],
      ),
    ],
    ownUnits: [_own(1)],
    section: _section,
    hqs: [
      HqView(
        team: 'team-blue',
        position: Position.metres(5000, 48500, 12.5),
        hp: 600,
        maxHp: 1000,
      ),
    ],
    hqsGone: const ['team-green'],
    relics: [
      RelicView(
        relicId: 'relic-4',
        position: Position.metres(3010, 23500, 9),
        owner: 'team-blue',
      ),
    ],
  ),
  'relic_alert': const RelicAlert(
    at: Duration(hours: 5, minutes: 12),
    relicId: 'relic-3',
    team: 'team-blue',
  ),
  'goodbye': const Goodbye(GoodbyeReason.battleEnded),
  // What a battle with test units lets a section buy (M7.7): prices as in
  // `economy.yaml`, the allowed weapons as in `units.yaml`.
  'roster': const Roster(
    units: [
      RosterUnit(
        unitType: 'soldier',
        category: 'soldier',
        price: 100,
        weapons: ['rifle', 'machine_gun'],
      ),
      RosterUnit(unitType: 'radio', category: 'radio', price: 100),
      RosterUnit(
        unitType: 'test_unit',
        category: 'soldier',
        price: 0,
        weapons: ['rifle', 'machine_gun', 'anti_tank', 'artillery'],
      ),
    ],
    weapons: [
      RosterWeapon(weapon: 'rifle', price: 100),
      RosterWeapon(weapon: 'machine_gun', price: 100),
      RosterWeapon(weapon: 'anti_tank', price: 100),
    ],
  ),
  // The sizes of stack/03's traffic estimate.
  'tick_one_moving_unit': TickUpdate(
    at: const Duration(hours: 5, seconds: 4, milliseconds: 400),
    moved: [_tenVehicles.first],
  ),
  'tick_ten_moving_vehicles': TickUpdate(
    at: const Duration(hours: 5, seconds: 4, milliseconds: 600),
    moved: _tenVehicles,
  ),
  'tick_rifle_shot': const TickUpdate(
    at: Duration(hours: 5, seconds: 4, milliseconds: 800),
    events: [
      Attacked(
        attackerId: 'u-rifle-5',
        sectionId: 's-1c9e',
        weapon: 'rifle',
        hit: true,
        impacts: [
          Impact(
            targetId: 'u-enemy-6',
            targetType: 'soldier',
            damage: 12,
            friendly: false,
            result: ImpactResult.damaged,
          ),
        ],
      ),
    ],
  ),
  'tick_unseen_hit': const TickUpdate(
    at: Duration(hours: 5, seconds: 5),
    unseenHits: [
      UnseenHit(
        targetId: 'u-rifle-3',
        damage: 12,
        result: ImpactResult.damaged,
      ),
    ],
  ),
  'section_view_16_units': SectionView(
    at: const Duration(hours: 5, seconds: 3),
    section: _section,
    units: [for (var i = 0; i < 16; i++) _own(i)],
    hqs: [
      HqView(
        team: 'team-red',
        position: Position.metres(4990, 1490, 31),
        hp: 1000,
        maxHp: 1000,
        ap: _ap,
      ),
    ],
    relics: [
      for (var i = 1; i <= 8; i++)
        RelicView(
          relicId: 'relic-$i',
          position: Position.metres(3000.0 + i * 50, 7000.0 + i * 5000, 20),
          owner: i.isEven ? 'team-red' : null,
        ),
    ],
    world: const [],
  ),
};
