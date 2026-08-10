# Résultat

Le principal goulot d’étranglement est clairement la désinscription des chemins VS Code.

Mesures effectuées sous macOS avec Bash 3.2, sur des copies temporaires des fichiers réels :

- fichiers shell RC : 147 à 716 octets
- `settings.json` VS Code : 4,3 Ko
- plusieurs répétitions
- scénario où les chemins existent
- scénario idempotent où les chemins sont déjà absents
- aucune instrumentation ajoutée au dépôt

À noter : le nom réel trouvé dans le code est `path_unregister_for_shell`, pas `ath_unregister_for_shell`.

## Temps global

| Opération | Temps réel typique |
|---|---:|
| Ensemble des 12 désinscriptions shell | environ `1,0 s` |
| Ensemble des 12 désinscriptions VS Code, chemins absents | environ `10,6 s` |
| Ensemble des 12 désinscriptions VS Code, chemins présents | environ `12,1 s` |
| `aistack_shell_purge` complet | environ `9 à 12,6 s` |

Une mesure séparant les temps donne :

| Opération | Réel | User | System |
|---|---:|---:|---:|
| Désinscriptions shell | `0,749 s` | `0,189 s` | `0,367 s` |
| Désinscriptions VS Code | `11,258 s` | `6,415 s` | `4,966 s` |
| `aistack_shell_purge` | `13,946 s` | `7,893 s` | `6,491 s` |

Selon la charge de la machine, la branche VS Code représente environ **85 à 93 % du temps total**.

## Branche shell

Chaîne d’appels :

```text
gemini_path_unregister_for_shell
└── path_unregister_for_shell
    └── unregister_for_shell
        ├── mktemp
        ├── awk
        ├── mv
        └── rm
```

Mesures par appel :

| Fonction | Temps typique |
|---|---:|
| `path_unregister_for_shell "gemini" "all"` | `53 ms` |
| `unregister_for_shell ... "all"` | `53 ms` |
| `unregister_for_shell ... "bash"` | `17,6 ms` |

Le wrapper `path_unregister_for_shell` est pratiquement gratuit. Le coût est entièrement dans `unregister_for_shell`.

Pour chaque outil et chaque shell, la fonction exécute :

```text
mktemp + awk + mv + rm
```

Avec 12 outils et 3 shells, cela représente jusqu’à :

```text
12 × 3 = 36 réécritures de fichiers RC
```

Même lorsqu’aucun bloc n’existe, le fichier est relu et réécrit.

La sous-fonction/opération la plus coûteuse de cette branche est donc le bloc de réécriture dans `unregister_for_shell`, particulièrement :

```bash
awk ... "${rc_file}" > "${tmp_file}" && mv "${tmp_file}" "${rc_file}"
```

Référence : `lib/lib.sh:1353`.

## Branche VS Code

Chaîne d’appels :

```text
gemini_path_unregister_for_vs_terminal
└── vscode_path_unregister_for_vs_terminal
    └── vscode_settings_remove_path_for_vs_terminal
        └── vscode_settings_tweak_path_for_vs_terminal
            ├── json_tweak_value_of_list_into_file
            │   ├── test_and_fix_json_file
            │   ├── json_tweak_value_of_list
            │   │   ├── json_escape_string_containing_char
            │   │   ├── jq
            │   │   └── json_escape_string_containing_char
            │   └── sanitize_json
            ├── vscode_get_config
            └── vscode_remove_config
                └── json_del_key_from_file
                    ├── test_and_fix_json_file
                    ├── json_has_path
                    └── sanitize_json
```

Mesures par outil :

| Fonction | Chemin absent | Chemin présent |
|---|---:|---:|
| `vscode_path_unregister_for_vs_terminal` | `720 ms` | `823 ms` |
| `vscode_settings_tweak_path_for_vs_terminal` | `673 ms` | `753 ms` |

Le wrapper VS Code est donc négligeable. Le coût se trouve dans `vscode_settings_tweak_path_for_vs_terminal`.

Cette fonction traite successivement deux clés :

```text
terminal.integrated.env.linux.PATH
terminal.integrated.env.osx.PATH
```

Référence : `lib/lib_vscode.sh:335`.

## Décomposition JSON

| Sous-fonction | Temps par appel |
|---|---:|
| `json_tweak_value_of_list_into_file`, une clé | `191 à 213 ms` |
| `json_del_key_from_file` | `135 à 170 ms` |
| `sanitize_json` | `99 à 115 ms` |
| `json_tweak_value_of_list`, flux seul | `71 à 81 ms` |
| `json_escape_string_containing_char`, mode `ESCAPE` | environ `32 ms` |
| `json_escape_string_containing_char`, mode `RESTORE` | environ `31 ms` |
| `vscode_get_config` | `25 à 34 ms` |
| `test_and_fix_json_file` | `13 à 14 ms` |

## Sous-fonctions les plus coûteuses

### 1. `sanitize_json`

Coût unitaire : `99 à 115 ms`.

Cette fonction démarre le programme Node.js `json5` et réécrit entièrement le fichier :

```bash
PATH="..." json5 -s 2 "${arg}" > "${tmp_file}"
mv "${tmp_file}" "${arg}"
```

Référence : `lib/lib_json.sh:147`.

Elle est appelée après chaque transformation JSON, y compris lorsqu’aucune correction JSON5 n’est nécessaire.

### 2. `json_del_key_from_file`

Coût : `135 à 170 ms`.

Lorsqu’une clé est déjà absente, cette fonction exécute tout de même :

```text
test_and_fix_json_file
json_has_path
sanitize_json
```

Le point particulièrement coûteux est :

```bash
if ! json_has_path ...; then
    sanitize_json "${target_file}"
    return 1
fi
```

Référence : `lib/lib_json.sh:425`.

Autrement dit, une clé absente provoque quand même un lancement de `json5` et une réécriture complète du fichier.

### 3. `json_tweak_value_of_list_into_file`

Coût : `191 à 213 ms` par clé.

Elle valide, transforme, déplace puis sanitize le fichier à chaque appel. Comme les clés Linux et macOS sont traitées séparément, le coût est doublé pour chaque outil.

Référence : `lib/lib_json.sh:507`.

### 4. `json_escape_string_containing_char`

Deux appels coûtent environ `63 ms` dans chaque transformation :

```text
ESCAPE  ≈ 32 ms
RESTORE ≈ 31 ms
```

Chaque appel crée un fichier temporaire et lance `jq`.

Référence : `lib/lib_json.sh:544`.

### 5. `unregister_for_shell`

Coût : environ `53 ms` pour les trois shells par outil.

Ce n’est pas le goulot principal, mais les 36 réécritures cumulées produisent environ une seconde de travail.

## Cause structurelle

Pour chaque outil VS Code, le code traite deux clés. Dans le cas idempotent, quand les clés sont absentes, le parcours approximatif est :

```text
2 × json_tweak_value_of_list_into_file
2 × vscode_get_config
2 × json_del_key_from_file
```

Cela entraîne approximativement, par outil :

```text
4 lancements de json5
plusieurs lancements de jq
plusieurs mktemp/mv/rm
plusieurs lectures et réécritures du même settings.json
```

Pour 12 outils :

```text
24 transformations de PATH
24 lectures de configuration
jusqu’à 24 tentatives de suppression de clé
environ 48 lancements de json5
```

C’est ce qui explique les `10 à 12 s`.

## Priorités d’optimisation

1. Regrouper tous les chemins à supprimer dans **une seule transformation `jq`** du `settings.json`.
2. Traiter les clés Linux et macOS dans la même transformation.
3. Ne lancer `sanitize_json` qu’une seule fois, avant traitement si le JSON est invalide, et non après chaque changement.
4. Dans `json_del_key_from_file`, retourner immédiatement lorsque la clé est absente, sans appeler `sanitize_json`.
5. Éviter `vscode_get_config` suivi de `vscode_remove_config` ; la transformation initiale peut directement supprimer une clé si son PATH devient vide.
6. Pour les fichiers shell, supprimer tous les blocs AIStack en une seule passe par fichier RC, soit 3 réécritures au lieu de 36.

Le gain potentiel principal se trouve donc dans `vscode_settings_tweak_path_for_vs_terminal` et ses sous-fonctions JSON. Une transformation groupée devrait théoriquement faire passer la branche VS Code de `10-12 s` à quelques centaines de millisecondes. Aucun fichier source n’a été modifié pendant ce profilage.
