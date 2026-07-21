import 'dart:math';

/// Messages affichés après la validation d'un défi (rotation aléatoire).
const successMessages = [
  'Bravo, un tampon de plus sur le carnet.',
  'Encore une étape gravée dans la glace.',
  'Le Grand Nord retient ce moment.',
  'Votre carnet s\'épaissit de souvenirs.',
  'Une pépite de plus dans l\'aventure.',
  'Les pédales tournent, le carnet aussi.',
  'Chaque défi relevé rapproche la ligne d\'arrivée.',
  'Le froid n\'a rien sur votre détermination.',
  'Un souvenir de plus pour le retour.',
  'La route est longue, mais vous avancez.',
  'Tampon nordique validé !',
  'Votre expédition gagne en richesse.',
  'Les flocons tombent, les exploits s\'accumulent.',
  'Un jour de plus, une histoire de plus.',
  'Le carnet de voyage s\'enrichit encore.',
];

String pickSuccessMessage({int? day}) {
  final rng = Random(day ?? DateTime.now().millisecondsSinceEpoch);
  return successMessages[rng.nextInt(successMessages.length)];
}

/// Sous-titre contextuel de l'accueil selon le jour du voyage.
String contextualDayMessage(int currentDay, int totalDays) {
  if (currentDay <= 1) return 'L\'aventure commence';
  if (currentDay >= totalDays) return 'Dernière étape';
  if (currentDay == (totalDays / 2).ceil()) return 'À mi-parcours';
  if (currentDay == totalDays - 1) return 'La ligne d\'arrivée approche';
  if (currentDay <= 3) return 'Les premiers kilomètres';
  return 'La route continue';
}
