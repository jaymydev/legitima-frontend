import Foundation

/// Une ligne de CV telle que /cv/parse la renvoie.
///
/// Exposée parce que les balises ont besoin du détail : le résumé texte perd la
/// séparation entre l'intitulé, la société et la période, et c'est justement
/// cette séparation qui permet de remplir des blancs sans rien demander.
// Codable, pas seulement Decodable : les lignes repartent vers le serveur dans
// une demande de personnalisation, et se gardent sur l'appareil entre-temps.
struct CVExperienceRow: Codable, Equatable {
    let title: String
    let company: String
    let period: String
}
