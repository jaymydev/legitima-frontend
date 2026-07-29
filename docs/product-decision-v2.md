# Décision produit V2 — Cadrage du parcours et du modèle freemium

Statut : **validé** (2026-07-29)
Portée : frontend iOS + implications backend. Ce document est la référence pour toutes les PR produit à venir. En cas de conflit avec un document plus ancien, ce document prévaut (AGENTS.md reste l'autorité sur les règles de contribution).

## 1. Problème constaté

L'app V1 « lean » livrait un générateur de rapport avec un paywall cosmétique :

- tout le contenu (gratuit et premium) provenait d'un seul appel `/analyze` effectué avant le paiement — l'achat révélait du texte déjà téléchargé, sans calcul nouveau ;
- la section la plus différenciante (requalification des zones sensibles) était gratuite, tandis que le contenu payant (anticipation d'objections) est ce que les LLM généralistes font déjà gratuitement ;
- le parcours premium redemandait des informations déjà saisies (use case, poste visé) ;
- aucun mécanisme ne ramenait l'utilisateur dans l'app après sa première session ;
- le tier gratuit affichait un habillage de dev (« Mode test », 20 analyses/jour).

## 2. Décision : A moteur, B livrable

Le job to be done de Legitima :

> **Aider l'utilisateur à défendre un parcours atypique lors d'un entretien précis, en partant du fil conducteur de sa carrière.**

- Le **récit requalifié** (option A historique) est le **moteur** : c'est le mécanisme différenciant. Un coach classique part de la question (« comment répondre à X ») ; Legitima part du récit et en déduit les réponses.
- Les **réponses défendables** (option B demandée par les testeurs) sont le **livrable** : c'est ce que l'utilisateur peut dire à voix haute en entretien.

Ce n'est pas un hybride flou mais une séquence :

| Tier | Rôle | Contenu |
|---|---|---|
| Gratuit | **Diagnostic** — la démonstration du mécanisme | Analyse lean : lecture stratégique, logique de carrière, requalification des zones sensibles (le « aha ») |
| Payant | **Accompagnement** — l'application du mécanisme | Préparation guidée pour SON type d'entretien : input riche collecté étape par étape, calcul réel via `/interview-preparation/*`, synthèse exportable |

Le moat n'est pas une section mais le mécanisme « récit → réponses ». La démonstration est gratuite, l'application est payante.

## 3. Le moment T de l'achat

**Décision :** l'achat déclenche un calcul réel (la préparation personnalisée), jamais un simple déverrouillage de texte déjà présent sur l'appareil.

- Les sections aujourd'hui verrouillées sur l'écran de résultat (objections, ancrage de légitimité, synthèse finale) deviennent des **teasers du résultat premium à générer**, pas du contenu pré-calculé masqué.
- La re-sélection de use case à froid après l'achat est supprimée : le parcours premium est la continuation directe de l'analyse gratuite (contexte conservé : poste, parcours, zone sensible).

**Point ouvert :** le design précis des 30 premières secondes post-achat (que voit l'utilisateur pendant la génération, comment la valeur est immédiatement perceptible). À trancher lors de la conception de l'écran.

## 4. Stratégie d'input

- **Gratuit = input lean** (3 champs actuels). C'est un entonnoir : suffisant pour produire un diagnostic-teaser, pas pour une préparation complète.
- **Payant = input riche, collecté progressivement.** Le flow guidé en étapes (existant : recruitment flow) interroge l'utilisateur question par question. L'utilisateur qui a payé accepte cet effort ; c'est aussi ce qui rend le payant vécu comme un accompagnement.
- **Validation de la qualité :**
  - côté gratuit : si l'input est trop maigre, l'analyse doit le signaler (« lecture partielle, précisez X pour l'affiner ») au lieu de générer avec la même assurance ;
  - côté payant : les questions guidées et les warnings qualité existants sont le mécanisme de validation.

## 5. Rétention

La rétention ne sert pas le même but selon le tier.

### Freemium — servir la conversion, pas l'engagement

- **Date d'entretien demandée dès le gratuit.** Donnée clé : elle justifie le retour (« votre entretien approche ») et déclenche la conversion. Meilleur levier identifié.
- **Brouillon persistant** (existant via `LocalPreparationStore`) : conservé.
- **Quota réaliste** : le quota de 20 analyses/jour est un garde-fou de dev, pas une offre. Cible : 2-3 analyses/jour, sans vocabulaire « Mode test » visible par l'utilisateur.

### Premium — servir l'usage et le réachat

1. **La veille de l'entretien** : la synthèse exportable est l'artefact de révision. Moment où l'app doit être indispensable.
2. **Le lendemain** : debrief post-entretien (« quelles questions vous ont mis en difficulté ? ») — deuxième usage, améliore la préparation suivante.
3. **L'entretien suivant** : un parcours atypique se défend différemment selon l'interlocuteur (RH, opérationnel, fondateur). Les use cases existants deviennent la mécanique de réachat : chaque type d'entretien est une préparation distincte.

**Point ouvert :** les relances (« entretien dans 2 jours ») supposent des notifications locales — feature nouvelle, hors scope V1, à approuver explicitement avant implémentation.

## 6. Dette à résorber avant TestFlight réel

- **Promesse d'export non tenue** : `PremiumUnlockCard` affiche « Synthèse premium exportable » alors qu'aucun export n'existe dans le code. À corriger (implémenter l'export ou retirer la promesse) avant tout test utilisateur réel.
- **Scaffolding de dev visible** : `TestAccessScreen` en écran racine, libellés « Mode test », quota 20/jour.

## 7. Ordre d'implémentation

Petites PR, dans cet ordre :

1. **Re-séquencement de l'achat (moment T)** : l'achat déclenche la préparation guidée ; sections verrouillées → teasers ; suppression de la re-sélection de use case.
2. **Date d'entretien** : saisie dès le gratuit, utilisée pour contextualiser les écrans.
3. **Export de la synthèse** : tenir la promesse d'achat.
4. **Debrief post-entretien** : deuxième usage premium.
5. **Nettoyage freemium** : quota réaliste, retrait du vocabulaire de test.

Chaque PR suit les règles de contribution : branche dédiée, un commit, `./scripts/check-build.sh`, screenshots pour toute UI.

## 8. Points ouverts récapitulés

| Point | À trancher quand |
|---|---|
| Design des 30 secondes post-achat | PR moment T |
| Valeur du quota freemium (2 ou 3/jour) | PR nettoyage freemium |
| Notifications locales (relances) | Après validation explicite — hors scope actuel |
| Format de l'export (PDF, texte, partage) | PR export |
