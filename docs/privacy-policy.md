# Politique de confidentialité — Legitima

**Dernière mise à jour : 3 septembre 2026**

> ⚠️ Ce document est une rédaction de départ, pas un avis juridique :
> faites-le relire si l'enjeu le justifie.

## En résumé

Legitima n'a pas de compte, pas de publicité, pas de traceur et aucune
bibliothèque tierce. Ce que vous écrivez reste sur votre téléphone. Le parcours
principal — les questions probables et leurs réponses à compléter — ne transmet
rien de ce que vous avez écrit. Seule la personnalisation facultative, si vous
la demandez, envoie votre texte à nos serveurs puis à OpenAI, le temps de
préparer vos réponses — puis il est effacé de la mémoire, sans être conservé.

## 1. Responsable du traitement

Milehana JOSEPH
Contact : contact@milehanajoseph.com

**Aucun délégué à la protection des données n'est désigné.** L'article 37 du
RGPD ne l'impose qu'aux autorités publiques, aux organismes dont l'activité
principale suppose un suivi systématique à grande échelle, ou à ceux traitant à
grande échelle des données sensibles — aucune de ces situations ici. L'adresse
ci-dessus est le point de contact pour toute question relative à vos données.

## 2. Ce que l'application traite

Legitima ne demande ni compte, ni identifiant, ni adresse e-mail. Aucune
inscription n'est possible, ni nécessaire.

Les seules données traitées sont celles que vous saisissez vous-même :

| Donnée | Nécessaire ? | Quitte votre appareil ? |
| --- | --- | --- |
| Le type d'entretien préparé | Nécessaire — c'est la seule réponse obligatoire | Oui, pour demander les bonnes questions ; ce n'est pas un texte de vous |
| Votre métier et le fait d'encadrer une équipe | Facultatifs | Oui, comme paramètres de la même demande |
| Ce que vous écrivez dans les blancs des réponses | Facultatif | **Non** — cela reste sur l'appareil |
| La date de votre entretien | Facultative — sert aux rappels locaux | **Non** |
| L'offre d'emploi collée, une réalisation racontée | Facultatives — servent à la personnalisation | Seulement si vous demandez la personnalisation |
| Le contenu d'un CV importé | Facultatif — c'est un raccourci de saisie | Au moment de l'import pour en extraire le texte, puis seulement si vous demandez une personnalisation **et** qu'il s'agit d'un entretien de recrutement ou de mobilité interne |

Sans le type d'entretien, aucune préparation n'est possible : c'est la matière
même du service. Tout le reste peut rester vide, et l'application fonctionne.

S'y ajoutent, si vous demandez la personnalisation, les textes produits à
partir de ces éléments.

L'application ne collecte aucune donnée de localisation, aucun identifiant
publicitaire, aucune statistique d'usage et aucun rapport de plantage.

## 3. Où ces données sont stockées

**Sur votre appareil uniquement.** Votre préparation est enregistrée dans
l'espace privé de l'application, protégée par le chiffrement d'iOS, et n'est
lisible par aucune autre application.

Il n'existe ni compte, ni synchronisation, ni sauvegarde sur nos serveurs.
Supprimer l'application efface l'intégralité de ces données. Elles peuvent en
revanche être incluses dans vos sauvegardes iCloud ou iTunes, selon les
réglages de votre appareil, qui relèvent de vous et d'Apple.

## 4. Ce qui est transmis, et à qui

Le parcours principal ne transmet aucun texte de vous : la demande des
questions porte le type d'entretien, le métier choisi et le fait d'encadrer —
rien d'autre.

Deux gestes, et deux seulement, font sortir du texte de votre appareil :
importer un CV, et demander une personnalisation. Le contenu de votre CV n'est
d'ailleurs joint à une demande de personnalisation que pour un **entretien de
recrutement ou de mobilité interne** — les deux seuls où il change quelque
chose à ce qui vous est proposé. Ailleurs, l'application ne vous le propose
même pas, et ne l'envoie pas : une donnée qui ne servirait à rien n'a pas à
voyager.

Le texte concerné est alors transmis :

1. à **Cloudflare, Inc.**, qui assure la protection et la distribution en
   frontal. La connexion depuis votre appareil est reçue par un point de
   présence proche de vous — Paris pour la France ;
2. puis à notre serveur, hébergé par **Render Services, Inc.** dans la région
   **Oregon (`us-west1`), aux États-Unis** ;
3. puis, pour la personnalisation seulement, à **OpenAI, L.L.C.**, aux
   **États-Unis**, qui exécute le modèle de langage préparant vos réponses.
   L'extraction du texte d'un CV se fait sur notre serveur, sans modèle de
   langage.

**Vos données quittent donc l'Union européenne dès la deuxième étape**, et non
seulement au moment de l'appel au modèle.

Notre serveur ne conserve rien : la requête est traitée puis la réponse vous
est renvoyée. Aucune base de données ne contient votre parcours.

Nos journaux techniques enregistrent la forme des requêtes — leur nombre, leur
durée, le type d'entretien préparé, si un champ était rempli — **jamais leur
contenu**. Des tests automatisés vérifient à chaque modification que le contenu
de vos réponses ne peut pas s'y retrouver.

Concernant OpenAI : les données envoyées via son interface de programmation ne
sont pas utilisées pour entraîner ses modèles, et sont conservées au maximum
30 jours à des fins de détection d'abus, conformément à sa politique applicable
aux appels d'API.

Les transferts vers Cloudflare, Render et OpenAI, tous établis aux États-Unis,
s'appuient sur les clauses contractuelles types de la Commission européenne
prévues à l'article 46 du RGPD.

## 5. Personnalisation automatisée

Les questions du parcours principal sont écrites à la main : aucun traitement
automatisé n'évalue votre situation pour vous les présenter.

Si vous demandez la personnalisation, un modèle de langage produit, sans
intervention humaine, des questions et des réponses à partir de ce que vous
avez écrit — ce qui touche à des éléments de votre vie professionnelle et peut
constituer un **profilage** au sens de l'article 4(4) du RGPD.

Deux précisions importantes :

- **Aucune décision n'est prise à votre sujet.** Le résultat vous est remis à
  vous, pour vous préparer. Il n'est transmis à aucun employeur, recruteur ou
  tiers, et ne produit aucun effet juridique. L'article 22, qui encadre les
  décisions automatisées, ne trouve donc pas à s'appliquer.
- **Le résultat est une proposition, pas un verdict.** Un modèle de langage
  peut se tromper ; ses réponses sont vérifiées contre ce que vous avez écrit,
  et vous restez seul juge de ce que vous direz en entretien.

## 6. Données sensibles

Les champs de Legitima sont libres. Vous pouvez donc y écrire, si vous le
souhaitez, une information relevant d'une catégorie particulière au sens de
l'article 9 du RGPD — un problème de santé, par exemple.

Les exemples proposés dans l'application portent volontairement sur des faits
d'emploi, jamais sur la santé. **Nous vous invitons à ne pas saisir
d'information de santé.** Décrire une interruption professionnelle sans en
donner la cause médicale suffit à la préparation.

Si vous en saisissez malgré tout, elles suivent le même chemin que le reste :
conservées sur votre appareil, transmises seulement si vous demandez la
personnalisation, jamais conservées côté serveur.

## 7. Base légale

Le traitement repose sur l'exécution du service que vous demandez
(article 6.1.b du RGPD) : sans le type d'entretien, aucune préparation n'est
possible, et sans le texte que vous choisissez d'envoyer, aucune
personnalisation ne l'est.

Pour les informations relevant de l'article 9 que vous choisiriez d'ajouter, le
traitement repose sur votre consentement explicite (article 9.2.a), donné par
le fait de les saisir volontairement dans un champ libre après cet
avertissement.

**Vous pouvez le retirer à tout moment**, et sans démarche auprès de nous :
effacez le texte concerné dans l'application. Il disparaît de votre appareil,
et il n'en existe aucune copie chez nous à supprimer. Le retrait ne remet pas
en cause les réponses déjà produites à partir de ce texte, que vous pouvez
également effacer.

## 8. Durées de conservation

| Donnée | Durée |
| --- | --- |
| Votre préparation, sur l'appareil | Jusqu'à ce que vous l'effaciez ou désinstalliez l'application |
| Contenu transmis à notre serveur (CV, personnalisation) | Le temps de la requête, jamais enregistré |
| Journaux techniques (sans contenu) | 30 jours |
| Données côté OpenAI (personnalisation seulement) | Jusqu'à 30 jours, selon sa politique API |

## 9. Autorisations demandées

- **Appareil photo** — uniquement si vous choisissez de photographier un CV.
  L'image est transmise pour en extraire le texte, puis n'est pas conservée.
- **Notifications** — uniquement si vous renseignez une date d'entretien. Les
  rappels sont produits localement par votre appareil ; aucun serveur ne vous
  envoie de notification et aucune donnée ne sort de l'appareil pour cela.

Les deux sont facultatives et l'application fonctionne sans.

## 10. Vos droits

Au titre du RGPD et de la loi Informatique et Libertés (loi n° 78-17 du
6 janvier 1978), vous disposez d'un droit d'accès, de rectification,
d'effacement, de limitation, d'opposition et de portabilité, ainsi que du droit
de définir des directives sur le sort de vos données après votre décès.

En pratique, l'absence de compte les rend immédiats : vos données sont sur
votre appareil, vous pouvez les modifier ou les effacer à tout moment depuis
l'application, et désinstaller l'application les supprime toutes. Nous ne
détenons rien qui vous soit rattachable.

Une précision utile : pour exercer ces droits ailleurs, il faut d'ordinaire
prouver son identité. Ici, non — nous ne détenons aucun compte permettant de
vous identifier, donc rien à vous demander et rien à vous restituer. C'est la
conséquence directe de ne rien conserver.

Pour toute question : contact@milehanajoseph.com.

Vous pouvez également introduire une réclamation auprès de la CNIL
(www.cnil.fr).

## 11. Mineurs

Legitima s'adresse à des personnes en activité ou en recherche d'emploi et
n'est pas destinée aux moins de 16 ans.

## 12. Modifications

Toute modification de cette politique sera publiée à cette adresse, avec une
date de mise à jour actualisée.
