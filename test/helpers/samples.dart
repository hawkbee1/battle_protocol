import 'package:battle_protocol/battle_protocol.dart';

/// One sample of every order, by its JSON type, with realistic values. The
/// committed encodings of these samples freeze version 1 of the format
/// (`test/fixtures/v1/`).
final sampleOrders = <String, Order>{
  'move': Move(
    unitId: 'u-jeep-7',
    to: Position.metres(1234.56, 789.01, 42.5),
    path: const [
      Cell(123, 78),
      Cell(124, 78),
      Cell(3, 4, island: 'sky'),
    ],
  ),
  'fire': const Fire(unitId: 'u-rifle-1', targetId: 'u-tank-3'),
  'fire_at_position': FireAtPosition(
    unitId: 'u-artillery-2',
    target: Position.metres(4000, -12.25, 0),
  ),
  'fire_aimed': FireAimed(
    unitId: 'u-rifle-1',
    aim: Direction.of(0.6, -0.8, 0.012345),
    fireTime: const Duration(hours: 30, milliseconds: 250, microseconds: 7),
  ),
  'reload': const Reload(unitId: 'u-rifle-1'),
  'unload_weapon': const UnloadWeapon(unitId: 'u-artillery-2'),
  'swap_weapon': const SwapWeapon(unitId: 'u-soldier-4', weapon: 'anti_air'),
  'pick_up_weapon': const PickUpWeapon(
    unitId: 'u-soldier-4',
    droppedId: 'w-17',
  ),
  'land': const Land(unitId: 'u-helicopter-1'),
  'take_off': const TakeOff(unitId: 'u-helicopter-1'),
  'embark': const Embark(unitId: 'u-soldier-4', transportId: 'u-truck-2'),
  'disembark': const Disembark(unitId: 'u-soldier-4'),
  'build': const Build(
    unitId: 'u-engineer-1',
    structure: 'reinforced_bridge',
    cells: [Cell(40, 12), Cell(41, 12), Cell(42, 12)],
  ),
  'repair': const Repair(unitId: 'u-engineer-1', targetId: 'u-tank-3'),
  'resume': const Resume(unitId: 'u-engineer-2', workId: 'wall@(40, 13)'),
  'heal': const Heal(unitId: 'u-medic-1', targetId: 'u-rifle-1'),
  'observe': const Observe(unitId: 'u-scout-1'),
  'capture': const Capture(unitId: 'u-rifle-1', relicId: 'relic-3'),
  'push': const Push(
    unitId: 'u-rifle-1',
    relicId: 'relic-3',
    path: [Cell(60, 20), Cell(61, 20), Cell(62, 21)],
  ),
  'store': const Store(unitId: 'u-rifle-1'),
  'recall': const Recall(unitId: 'u-tank-3'),
  'deploy': const Deploy(unitId: 'u-tank-3'),
  'buy_node': const BuyNode(unitId: 'u-tank-3', stat: 'move_speed', step: 4),
  'move_hq': MoveHq(to: Position.metres(5010, 220, 31)),
  'buy_unit': const BuyUnit(unitType: 'radio'),
  'buy_weapon': const BuyWeapon(weapon: 'machine_gun'),
  'buy_guild_camp': const BuyGuildCamp(),
  'transfer_money': const TransferMoney(toSectionId: 's-8f2a', amount: 250),
  'offer_exchange': const OfferExchange(
    ownerSectionId: 's-8f2a',
    released: ['u-enemy-1', 'u-enemy-2'],
    wanted: ['u-rifle-9'],
  ),
  'offer_ransom': const OfferRansom(
    ownerSectionId: 's-8f2a',
    released: ['u-enemy-3'],
    price: 300,
  ),
  'accept_offer': const AcceptOffer(offerId: 1024),
  'refuse_offer': const RefuseOffer(offerId: 1025),
  'delegate_hq': const DelegateHq(accountId: 'a-6531d2f0b8c4'),
  'enter_battle': const EnterBattle(),
  'admit_section': const AdmitSection(
    team: 'blue',
    money: 500,
    units: [AdmittedUnit(unitId: 's-1c9e-commander', unitType: 'commander')],
  ),
};

const _sender = Sender(accountId: 'a-6531d2f0b8c4', sectionId: 's-1c9e');

/// One command per order, stamped as the host logs them, with the three
/// origins in turn.
final sampleCommands = <String, Command>{
  for (final (i, MapEntry(:key, :value)) in sampleOrders.entries.indexed)
    key: Command(
      sender: _sender,
      sentAt: Duration(seconds: 3600 + i, microseconds: 125),
      order: value,
    ).stamped(origin: Origin.values[i % 3], seq: 1000 + i),
  'unstamped_move': Command(
    sender: _sender,
    sentAt: const Duration(seconds: 42),
    order: Move(unitId: 'u-rifle-1', to: Position.metres(10, 20, 0)),
  ),
};

/// One sample of every event, by its JSON type.
final sampleEvents = <String, BattleEvent>{
  'order_refused': const OrderRefused(seq: 1001, reason: 'not_enough_ap'),
  'order_delayed': const OrderDelayed(
    seq: 1002,
    until: Duration(hours: 2, seconds: 30),
  ),
  'move_started': const MoveStarted(
    moverId: 'u-jeep-7',
    arrivesAt: Duration(seconds: 3612, microseconds: 345678),
  ),
  'move_stopped': MoveStopped(
    moverId: 'hq-red',
    at: Position.metres(5003.4, 221, 31),
  ),
  'attacked': const Attacked(
    attackerId: 'u-artillery-2',
    sectionId: 's-1c9e',
    weapon: 'artillery',
    hit: false,
    impacts: [
      Impact(
        targetId: 'u-rifle-9',
        targetType: 'soldier',
        damage: 38.5,
        friendly: true,
        result: ImpactResult.killed,
      ),
      Impact(
        targetId: 'u-enemy-4',
        targetType: 'commander',
        damage: 12.125,
        friendly: false,
        result: ImpactResult.damaged,
      ),
      Impact(
        targetId: 'tree@(3, 4)',
        targetType: 'tree',
        damage: 0.1,
        friendly: false,
        result: ImpactResult.prisoner,
      ),
      Impact(
        targetId: 'u-enemy-5',
        targetType: 'jeep',
        damage: 180,
        friendly: false,
        result: ImpactResult.defected,
      ),
    ],
  ),
  'crushed': const Crushed(
    byId: 'relic-3',
    unitId: 'u-enemy-6',
    unitType: 'soldier',
  ),
  'weapon_dropped': WeaponDropped(
    droppedId: 'w-17',
    weapon: 'rifle',
    at: Position.metres(812.07, 333.3, 12),
    goneAt: const Duration(hours: 4),
  ),
  'weapon_picked_up': const WeaponPickedUp(
    unitId: 'u-soldier-4',
    droppedId: 'w-17',
  ),
  'weapon_swapped': const WeaponSwapped(
    unitId: 'u-soldier-4',
    weapon: 'anti_air',
    readyAt: Duration(seconds: 3605),
  ),
  'time_only_started': const TimeOnlyStarted(
    unitId: 'u-helicopter-1',
    action: TimeOnly.takeOff,
    endsAt: Duration(seconds: 3630),
  ),
  'embarked': const Embarked(unitId: 'u-soldier-4', transportId: 'u-truck-2'),
  'disembarked': Disembarked(
    unitId: 'u-soldier-4',
    at: Position.metres(900, 401.5, 8.25),
  ),
  'build_started': const BuildStarted(
    unitId: 'u-engineer-1',
    siteId: 'reinforced_bridge@(40, 12)',
    structure: 'reinforced_bridge',
    cells: [Cell(40, 12), Cell(41, 12), Cell(42, 12)],
    endsAt: Duration(minutes: 70),
  ),
  'repair_started': const RepairStarted(
    unitId: 'u-engineer-1',
    targetId: 'u-tank-3',
    endsAt: Duration(minutes: 75),
  ),
  'work_resumed': const WorkResumed(
    unitId: 'u-engineer-2',
    workId: 'wall@(40, 13)',
    endsAt: Duration(minutes: 80),
  ),
  'work_interrupted': const WorkInterrupted(
    unitId: 'u-engineer-2',
    workId: 'wall@(40, 13)',
  ),
  'structure_built': const StructureBuilt(
    siteId: 'ladder@(7, 9)',
    structure: 'ladder',
    cells: [
      Cell(7, 9),
      Cell(2, 2, island: 'sky'),
    ],
  ),
  'repaired': const Repaired(targetId: 'u-tank-3', hp: 400),
  'unit_healed': const UnitHealed(
    unitId: 'u-medic-1',
    targetId: 'u-rifle-1',
    hp: 47.5,
  ),
  'observation_started': const ObservationStarted(
    unitId: 'u-scout-1',
    endsAt: Duration(minutes: 90),
  ),
  'added_to_capture': const AddedToCapture(
    unitId: 'u-rifle-1',
    relicId: 'relic-3',
    potAp: 50,
    capturedAt: Duration(hours: 1, minutes: 30),
  ),
  'added_to_push': const AddedToPush(
    unitId: 'u-rifle-1',
    relicId: 'relic-3',
    potAp: 15,
  ),
  'capture_lost': const CaptureLost(relicId: 'relic-3', team: 'blue'),
  'relic_captured': const RelicCaptured(
    relicId: 'relic-3',
    team: 'red',
    previousOwner: 'blue',
  ),
  'relic_lost': const RelicLost(relicId: 'relic-5'),
  'victory_hold_started': const VictoryHoldStarted(
    team: 'red',
    winsAt: Duration(days: 3, hours: 2),
  ),
  'victory_hold_reset': const VictoryHoldReset(team: 'red'),
  'eliminated': const Eliminated(team: 'green', loss: HqLoss.lostWithBridge),
  'unit_stored': const UnitStored(unitId: 'u-rifle-1'),
  'recall_began': const RecallBegan(
    unitId: 'u-tank-3',
    storedAt: Duration(hours: 7),
  ),
  'unit_deployed': UnitDeployed(
    unitId: 'u-tank-3',
    at: Position.metres(5015.5, 230, 31),
  ),
  'section_locked': const SectionLocked(
    sectionId: 's-1c9e',
    until: Duration(days: 1, hours: 7),
  ),
  'unit_purchased': const UnitPurchased(
    sectionId: 's-1c9e',
    unitId: 'u-radio-1',
    unitType: 'radio',
    price: 100,
  ),
  'weapon_purchased': const WeaponPurchased(
    sectionId: 's-1c9e',
    weapon: 'machine_gun',
    price: 100,
  ),
  'money_transferred': const MoneyTransferred(
    fromSectionId: 's-1c9e',
    toSectionId: 's-8f2a',
    received: 245,
    fee: 5,
  ),
  'node_purchased': const NodePurchased(
    unitId: 'u-tank-3',
    stat: 'move_speed',
    step: 4,
  ),
  'offer_posted': const OfferPosted(
    offerId: 1024,
    captorSectionId: 's-1c9e',
    ownerSectionId: 's-8f2a',
    released: ['u-enemy-1', 'u-enemy-2'],
    wanted: ['u-rifle-9'],
    price: 0,
  ),
  'offer_accepted': const OfferAccepted(offerId: 1024),
  'offer_refused': const OfferRefused(offerId: 1025),
  'manager_changed': const ManagerChanged(
    team: 'red',
    accountId: 'a-6531d2f0b8c4',
  ),
  'battle_started': const BattleStarted(
    battleId: 'b-2026-11-war-1',
    mapId: 'valley',
    seed: 3735928559,
  ),
  'battle_ended': const BattleEnded(
    winner: 'red',
    kind: WinKind.relics,
    eliminated: ['green', 'blue'],
  ),
  'object_damaged': const ObjectDamaged(
    object: 'wall',
    cells: [Cell(31, 7)],
    hp: 120.5,
  ),
  'object_destroyed': const ObjectDestroyed(
    object: 'ladder',
    cells: [
      Cell(12, 4),
      Cell(13, 4, island: 'north'),
    ],
  ),
  'crater_dug': CraterDug(
    at: Position.metres(5003.4, 221, 31),
    radiusM: 8,
    depthM: 1.5,
  ),
  'section_joined': const SectionJoined(
    sectionId: 'sec-7',
    accountId: 'acc-7',
    team: 'red',
    units: [
      JoinedUnit(unitId: 'cmd-7', unitType: 'commander'),
      JoinedUnit(unitId: 'sol-71', unitType: 'soldier'),
    ],
  ),
};

/// Log entries: the battle start, an attack with its outcome in the same
/// entry, an order that waits and its later outcome, and a capture.
final sampleEntries = <String, LogEntry>{
  'battle_start': LogEntry(
    at: Duration.zero,
    events: [sampleEvents['battle_started']!, sampleEvents['manager_changed']!],
  ),
  'attack': LogEntry(
    at: const Duration(seconds: 3602, microseconds: 1),
    command: sampleCommands['fire_at_position'],
    events: [sampleEvents['attacked']!, sampleEvents['weapon_dropped']!],
  ),
  'delayed_heal': LogEntry(
    at: const Duration(seconds: 3615),
    command: sampleCommands['heal'],
    events: const [OrderDelayed(seq: 1015, until: Duration(hours: 2))],
  ),
  'heal_done': LogEntry(
    at: const Duration(hours: 2),
    events: [sampleEvents['unit_healed']!],
  ),
  'capture_done': LogEntry(
    at: const Duration(hours: 1, minutes: 30),
    events: [sampleEvents['relic_captured']!],
  ),
};
