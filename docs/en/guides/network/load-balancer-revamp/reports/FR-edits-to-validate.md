# FR naturalization — edits to validate

Exact `before → after` for every naturalization edit, extracted from the 6 subagent transcripts (+ 4 manual what-is edits). Validate each.

_Note: one extra edit in troubleshooting.mdx was applied via a shell (perl) command, not the Edit tool, so it is not listed here._


## architecture-blue-green.mdx

**1.**

```diff
- Ce guide présente une architecture de référence qui met en œuvre ce modèle sur OVHcloud Load Balancer. Il transpose le modèle blue-green sur les composants de base du Load Balancer, les fermes de serveurs et les frontends, et détaille le basculement.
+ Ce guide présente une architecture de référence qui met en œuvre ce modèle sur OVHcloud Load Balancer. Il transpose le blue-green sur les composants de base du Load Balancer, les fermes de serveurs et les frontends, et détaille le basculement.
```

**2.**

```diff
- Comme vous pouvez modifier et réappliquer à tout moment la ferme par défaut d'un frontend, le lien entre un port public et un environnement backend est une valeur de configuration, et non un câblage figé. Ce découplage rend le basculement possible.
+ Comme la ferme par défaut d'un frontend peut être modifiée et réappliquée à tout moment, le lien entre un port public et un environnement backend relève de la configuration, et non d'un câblage figé. C'est ce découplage qui rend le basculement possible.
```

**3.**

```diff
- Le basculement consiste à échanger la valeur `defaultFarmId` sur les deux frontends, suivi d'une seule opération d'application. Aucun serveur backend n'est déplacé, recréé ou reconfiguré pendant la bascule.
+ Le basculement consiste à échanger la valeur `defaultFarmId` sur les deux frontends, puis à appliquer la configuration en une seule opération. Aucun serveur backend n'est déplacé, recréé ou reconfiguré pendant la bascule.
```

**4.**

```diff
- Après un basculement réussi, le frontend public pointe vers la Ferme B et le frontend de préproduction pointe vers la Ferme A. Les couleurs suivent le rôle, et non la ferme : la ferme en production est toujours « blue ».
+ Après un basculement réussi, le frontend public pointe vers la Ferme B et le frontend de préproduction vers la Ferme A. Les couleurs suivent le rôle, et non la ferme : la ferme en production est toujours « blue ».
```

**5.**

```diff
- Cette section crée les deux fermes de serveurs et rattache les serveurs backend qui hébergent chaque environnement. Répétez la procédure deux fois, une fois pour la Ferme A et une fois pour la Ferme B.
+ Cette section crée les deux fermes de serveurs et rattache les serveurs backend qui hébergent chaque environnement. Répétez la procédure deux fois : une fois pour la Ferme A, une fois pour la Ferme B.
```

**6.**

```diff
- Répétez la procédure deux fois : une fois pour la Ferme A, une fois pour la Ferme B.
+ Répétez la procédure deux fois : une fois pour la Ferme A, une fois pour la Ferme B.
```

**7.**

```diff
- Répétez la procédure deux fois : une fois pour la Ferme A, une fois pour la Ferme B.
+ Répétez la procédure deux fois, une fois pour la Ferme A, une fois pour la Ferme B.
```

**8.**

```diff
- Avant de basculer, déployez et testez votre nouvelle version sur l'environnement situé derrière la Ferme B, en l'atteignant par le port de préproduction (`8888`). Ne poursuivez que lorsque la version candidate a passé la validation.
+ Avant de basculer, déployez et testez votre nouvelle version sur l'environnement situé derrière la Ferme B, en l'atteignant par le port de préproduction (`8888`). Ne poursuivez qu'une fois la version candidate validée.
```

**9.**

```diff
- Cette section annule le basculement si la nouvelle version se comporte mal en production. Comme l'environnement précédent n'est pas modifié et reste rattaché à la Ferme A, le retour arrière est la même opération exécutée en sens inverse.
+ Cette section annule le basculement si la nouvelle version se comporte mal en production. Comme l'environnement précédent reste intact et rattaché à la Ferme A, le retour arrière est la même opération exécutée en sens inverse.
```


## architecture-http-https.mdx

**10.**

```diff
- Les deux frontends acheminent le trafic vers la même ferme de serveurs HTTP, qui répartit le trafic sur un ou plusieurs serveurs web backend. Cela conserve un pool de backends unique derrière les deux points d'entrée, de sorte que l'application est servie de manière identique en HTTP et en HTTPS.
+ Les deux frontends acheminent le trafic vers la même ferme de serveurs HTTP, qui le répartit sur un ou plusieurs serveurs web backend. Les deux points d'entrée partagent ainsi un même pool de backends, et l'application est servie de manière identique en HTTP et en HTTPS.
```

**11.**

```diff
- La session TLS est terminée au niveau du Load Balancer ; la connexion entre le Load Balancer et les serveurs backend se fait donc en HTTP non chiffré dans cette architecture. Conservez le réseau des backends privé ou de confiance.
+ La session TLS est terminée au niveau du Load Balancer ; dans cette architecture, la connexion entre le Load Balancer et les serveurs backend se fait donc en HTTP non chiffré. Conservez le réseau des backends privé ou de confiance.
```

**12.**

```diff
- la connexion entre le Load Balancer et les serveurs backend se fait donc en HTTP non chiffré dans cette architecture. Conservez le réseau des backends privé ou de confiance.
+ dans cette architecture, la connexion entre le Load Balancer et les serveurs backend se fait donc en HTTP non chiffré. Conservez le réseau des backends privé ou de confiance.
```

**13.**

```diff
- | Zone unique | Cette architecture suppose une seule zone. La résilience multizone constitue une architecture distincte. Consultez [architecture résiliente multizone](/guides/network/load-balancer-revamp/architecture-resilient-multi-zone). |
+ | Zone unique | Cette architecture suppose une seule zone. La résilience multizone fait l'objet d'une architecture distincte. Consultez [architecture résiliente multizone](/guides/network/load-balancer-revamp/architecture-resilient-multi-zone). |
```

**14.**

```diff
- L'ordre dans lequel vous créez les éléments a son importance, car certains objets dépendent d'autres.
+ L'ordre de création a son importance, car certains objets dépendent d'autres.
```

**15.**

```diff
- Les fermes de serveurs doivent exister avant que vous puissiez y rattacher des serveurs ou définir la ferme par défaut d'un frontend.
+ Une ferme de serveurs doit exister avant de pouvoir y rattacher des serveurs ou la définir comme ferme par défaut d'un frontend.
```


## architecture-resilient-multi-zone.mdx

**16.**

```diff
- Le modèle que vous choisissez dépend de votre priorité : la reprise après une panne régionale étendue ou la haute disponibilité au sein d'une seule région.
+ Le choix du modèle dépend de votre priorité : la reprise après une panne régionale étendue ou la haute disponibilité au sein d'une seule région.
```

**17.**

```diff
- Vous pouvez répartir un service OVHcloud Load Balancer sur plusieurs zones de deux manières. Le modèle que vous choisissez dépend de votre priorité
+ Vous pouvez répartir un service OVHcloud Load Balancer sur plusieurs zones de deux manières. Le choix du modèle dépend de votre priorité
```

**18.**

```diff
- Cela maintient le trafic local à une zone en conditions normales et isole l'impact de la défaillance d'une zone.
+ En conditions normales, le trafic reste ainsi local à chaque zone, ce qui isole l'impact de la défaillance d'une zone.
```


## automation.mdx

**19.**

```diff
- L'espace client convient à une administration interactive, tandis que l'API et Terraform constituent le socle de l'automatisation, des déploiements reproductibles et de l'intégration aux pipelines de livraison continue.
+ L'espace client convient à une administration interactive, tandis que l'API et Terraform servent de base à l'automatisation, aux déploiements reproductibles et à l'intégration aux pipelines de livraison continue.
```

**20.**

```diff
- Ce modèle vous permet d'assembler un ensemble complet de changements liés (par exemple, ajouter une ferme, y rattacher plusieurs serveurs et créer un frontend qui pointe vers la ferme) puis de les déployer ensemble en une seule opération cohérente. Il réduit également le risque d'exposer une configuration incomplète au trafic de production.
+ Ce modèle vous permet de préparer un ensemble complet de changements liés (par exemple ajouter une ferme, y rattacher plusieurs serveurs et créer un frontend qui pointe vers cette ferme), puis de les déployer ensemble en une seule opération cohérente. Il réduit également le risque d'exposer une configuration incomplète au trafic de production.
```

**21.**

```diff
- Chaque composant dispose donc d'un ensemble distinct d'endpoints par protocole : vous devez appeler l'endpoint qui correspond au composant que vous gérez.
+ Chaque composant dispose donc d'un ensemble distinct d'endpoints par protocole : appelez l'endpoint correspondant au composant que vous gérez.
```

**22.**

```diff
- vous devez appeler l'endpoint qui correspond au composant que vous gérez.
+ appelez l'endpoint correspondant au composant que vous gérez.
```


## availability-and-zones.mdx

**23.**

```diff
- La plupart des régions n'exposent historiquement qu'une seule zone : travailler avec plusieurs zones revient donc généralement à travailler avec plusieurs régions. Les régions multi-AZ font exception : elles exposent plusieurs zones indépendantes au sein d'une même région, reliées par des liens à faible latence.
+ La plupart des régions n'exposent historiquement qu'une seule zone : recourir à plusieurs zones revient donc généralement à recourir à plusieurs régions. Les régions multi-AZ font exception : elles exposent plusieurs zones indépendantes au sein d'une même région, reliées par des liens à faible latence.
```

**24.**

```diff
- Pour bénéficier de ce modèle, définissez un frontend dans chaque zone qui pointe vers un cluster situé dans la même zone. Vous pouvez alors déclarer des serveurs backend différents par zone et contrôler quels serveurs backend servent quelle région.
+ Pour bénéficier de ce modèle, définissez dans chaque zone un frontend qui pointe vers un cluster situé dans la même zone. Vous pouvez alors déclarer des serveurs backend différents par zone et contrôler quels serveurs backend servent quelle région.
```


## cancel-load-balancer.mdx

**25.**

```diff
- Vous pouvez résilier votre Load Balancer depuis l'espace client ou via l'API OVHcloud. Choisissez le canal qui correspond à votre méthode de travail.
+ Vous pouvez résilier votre Load Balancer depuis l'espace client ou via l'API OVHcloud. Choisissez la méthode qui correspond à vos habitudes de travail.
```


## configure-frontends.mdx

**26.**

```diff
- Un frontend constitue le point d'entrée d'écoute de votre OVHcloud Load Balancer. Il définit le protocole et le port sur lesquels le trafic client est accepté, les zones où il est exposé, ainsi que la ferme par défaut qui reçoit le trafic. Ce guide vous accompagne dans la création et la modification de frontends HTTP, TCP et UDP, à la fois depuis l'espace client OVHcloud et l'API OVHcloud.
+ Un frontend est le point d'entrée d'écoute de votre OVHcloud Load Balancer. Il définit le protocole et le port sur lesquels le trafic client est accepté, les zones où il est exposé, ainsi que la ferme par défaut qui reçoit le trafic. Ce guide vous accompagne dans la création et la modification de frontends HTTP, TCP et UDP, depuis l'espace client OVHcloud comme via l'API OVHcloud.
```

**27.**

```diff
- > L'ordre de création des éléments est important. Une ferme de serveurs doit exister avant que vous ne créiez le frontend qui la cible, car la route par défaut du frontend pointe vers une ferme existante. Les modifications de configuration ne prennent effet qu'une fois appliquées dans chaque zone.
+ > L'ordre de création des éléments est important. Une ferme de serveurs doit exister avant que vous ne créiez le frontend qui la cible, car la route par défaut du frontend pointe vers une ferme existante. Les modifications de configuration ne prennent effet qu'une fois appliquées dans chaque zone.
+ 
+ 
```

**28.**

```diff
- > Les modifications de configuration ne prennent effet qu'une fois appliquées dans chaque zone.
- 
- 
+ > Les modifications de configuration ne prennent effet qu'une fois appliquées dans chaque zone.
+ 
```

**29.**

```diff
- appliquées dans chaque zone.
- 
- 
- 
- ## Prérequis
+ appliquées dans chaque zone.
+ 
+ ## Prérequis
```

**30.**

```diff
- La modification d'un frontend vous permet de changer son protocole, son port, sa zone d'exposition, sa ferme par défaut ou son certificat associé. Les modifications ne prennent effet qu'après que vous avez appliqué la configuration dans chaque zone.
+ Modifier un frontend vous permet de changer son protocole, son port, sa zone d'exposition, sa ferme par défaut ou son certificat associé. Les modifications ne prennent effet qu'une fois la configuration appliquée dans chaque zone.
```

**31.**

```diff
- Les modifications de frontend ne sont actives qu'une fois que vous avez appliqué la configuration dans chaque zone où le service est déployé. Cela vous permet de préparer plusieurs modifications et de les publier en une seule étape.
+ Les modifications de frontend ne deviennent actives qu'une fois la configuration appliquée dans chaque zone où le service est déployé. Vous pouvez ainsi préparer plusieurs modifications et les publier en une seule étape.
```

**32.**

```diff
- > Les certificats ajoutés au service sont disponibles pour chaque frontend sur lequel le TLS est activé. Vous n'associez pas un certificat par frontend dans une étape distincte au-delà de l'activation du TLS et de sa sélection.
+ > Les certificats ajoutés au service sont disponibles pour chaque frontend sur lequel le TLS est activé. Il n'y a pas d'association de certificat à faire frontend par frontend : il suffit d'activer le TLS et de sélectionner le certificat.
```


## configure-health-probes.mdx

**33.**

```diff
- Les sondes se configurent **au niveau de la ferme**, si bien que tous les serveurs d'une même ferme utilisent la même définition de sonde. Toutefois, la sonde doit également être **activée par serveur**, ce qui vous permet de surveiller uniquement certains serveurs d'une ferme.
+ Les sondes se configurent **au niveau de la ferme** : tous les serveurs d'une même ferme utilisent donc la même définition de sonde. La sonde doit toutefois aussi être **activée serveur par serveur**, ce qui vous permet de ne surveiller que certains serveurs d'une ferme.
```

**34.**

```diff
- Lorsqu'une sonde détecte une erreur, le serveur concerné est automatiquement retiré de la rotation jusqu'à ce qu'il se rétablisse, de sorte que le trafic n'est jamais acheminé vers un backend qui ne répond pas.
+ Lorsqu'une sonde détecte une erreur, le serveur concerné est automatiquement retiré de la rotation jusqu'à son rétablissement : le trafic n'est ainsi jamais acheminé vers un backend qui ne répond pas.
```

**35.**

```diff
- Configurer une sonde sur une ferme ne suffit pas à elle seule. La sonde doit également être activée sur chaque serveur que vous souhaitez surveiller (voir l'étape 2).
+ Configurer une sonde sur une ferme ne suffit pas. La sonde doit aussi être activée sur chaque serveur que vous souhaitez surveiller (voir l'étape 2).
```

**36.**

```diff
- Il s'agit de la sonde la plus simple ; elle fonctionne aussi bien sur les fermes `tcp` que `http`. Elle ouvre périodiquement une connexion vers chaque serveur ; si la connexion échoue deux fois de suite, le serveur est retiré de la rotation jusqu'à ce qu'il réponde de nouveau.
+ C'est la sonde la plus simple ; elle fonctionne aussi bien sur les fermes `tcp` que `http`. Elle ouvre périodiquement une connexion vers chaque serveur ; si la connexion échoue deux fois de suite, le serveur est retiré de la rotation jusqu'à ce qu'il réponde de nouveau.
```


## configure-http-headers.mdx

**37.**

```diff
- **Ce guide explique comment utiliser les en-têtes par défaut ajoutés par le Load Balancer, comment leur faire confiance en toute sécurité sur vos serveurs backend, et comment ajouter des en-têtes personnalisés sur un frontend HTTP.**
- 
- Ce guide est fait pour vous si vos journaux d'accès (`access_log`) n'affichent que des adresses IP privées telles que `10.108.x.y`.
+ **Ce guide explique comment utiliser les en-têtes par défaut ajoutés par le Load Balancer, comment les exploiter en toute sécurité sur vos serveurs backend, et comment ajouter des en-têtes personnalisés sur un frontend HTTP.**
+ 
+ Ce guide est fait pour vous si vos journaux d'accès (`access_log`) n'affichent que des adresses IP privées comme `10.108.x.y`.
```

**38.**

```diff
- Modifier uniquement la directive de format des journaux ne suffit pas, car n'importe qui peut définir l'en-tête `X-Forwarded-For` sans passer par votre Load Balancer. Le module dédié de chaque serveur web contrôle le niveau de confiance en fonction de :
+ Modifier seulement la directive de format des journaux ne suffit pas, car n'importe qui peut définir l'en-tête `X-Forwarded-For` sans passer par votre Load Balancer. Le module dédié de chaque serveur web détermine le niveau de confiance à partir de :
```

**39.**

```diff
- Modifier uniquement la directive de format des journaux ne suffit pas, car n'importe qui peut définir l'en-tête `X-Forwarded-For` sans passer par votre Load Balancer. Le module dédié de chaque serveur web contrôle le niveau de confiance en fonction de
+ Modifier seulement la directive de format des journaux ne suffit pas, car n'importe qui peut définir l'en-tête `X-Forwarded-For` sans passer par votre Load Balancer. Le module dédié de chaque serveur web détermine le niveau de confiance à partir de
```

**40.**

```diff
- - La profondeur de l'adresse IP dans l'en-tête, puisque chaque proxy ajoute l'IP du client au champ.
+ - La position de l'adresse IP dans l'en-tête, chaque proxy y ajoutant l'IP du client.
```


## configure-http-routes.mdx

**41.**

```diff
- Une **route** ajoute une logique conditionnelle par-dessus ce mécanisme : une action exécutée lorsqu'une ou plusieurs conditions sont remplies.
+ Une **route** ajoute une logique conditionnelle par-dessus ce mécanisme : une action déclenchée lorsqu'une ou plusieurs conditions sont remplies.
```

**42.**

```diff
- Assimilez ce modèle avant de créer la moindre route.
+ Familiarisez-vous avec ce modèle avant de créer votre première route.
```


## configure-http2.mdx

**43.**

```diff
- Le traitement reste ainsi minimal et la latence faible, mais il ne peut pas réaliser d'optimisations applicatives telles que le routage basé sur le contenu ou la manipulation des en-têtes HTTP.
+ Le traitement reste ainsi minimal et la latence faible, mais aucune optimisation applicative n'est possible, comme le routage basé sur le contenu ou la manipulation des en-têtes HTTP.
```


## configure-logs-forwarding.mdx

**44.**

```diff
- Le transfert des logs ingère les logs d'un service OVHcloud dans un flux de données LDP au sein du même compte OVHcloud. Vous l'activez service par service. Lorsque vous activez le transfert pour un Load Balancer vers un flux de données, un *abonnement* est créé et rattaché à ce flux en vue de sa gestion ultérieure.
+ Le transfert des logs ingère les logs d'un service OVHcloud dans un flux de données LDP au sein du même compte OVHcloud. Il s'active service par service. Lorsque vous activez le transfert d'un Load Balancer vers un flux de données, un *abonnement* est créé et rattaché à ce flux pour sa gestion ultérieure.
```


## configure-proxy-protocol.mdx

**45.**

```diff
- Étant donné que l'en-tête modifie le début du flux TCP, le serveur backend doit être configuré pour s'y attendre et l'analyser. Le protocole existe en deux versions :
+ Comme l'en-tête modifie le début du flux TCP, le serveur backend doit être configuré pour s'y attendre et l'analyser. Le protocole existe en deux versions :
```

**46.**

```diff
- Étant donné que l'en-tête modifie le début du flux TCP, le serveur backend doit être configuré pour s'y attendre et l'analyser.
+ Comme l'en-tête modifie le début du flux TCP, le serveur backend doit être configuré pour s'y attendre et l'analyser.
```

**47.**

```diff
- L'activation du ProxyProtocol comporte deux parties. Tout d'abord, activez le mode ProxyProtocol sur le serveur backend dans votre OVHcloud Load Balancer. Ensuite, configurez ce serveur backend pour qu'il accepte et analyse l'en-tête.
+ L'activation du ProxyProtocol se fait en deux temps. Activez d'abord le mode ProxyProtocol sur le serveur backend dans votre OVHcloud Load Balancer, puis configurez ce serveur backend pour qu'il accepte et analyse l'en-tête.
```

**48.**

```diff
- Pour configurer la confiance sur vos serveurs backend, vous avez besoin de la liste des adresses IP de sortie de votre OVHcloud Load Balancer. Récupérez-les avant de commencer.
+ Pour paramétrer la confiance sur vos serveurs backend, il vous faut la liste des adresses IP de sortie de votre OVHcloud Load Balancer. Récupérez-les avant de commencer.
```

**49.**

```diff
- Un modèle courant consiste à placer une instance HAProxy locale devant un logiciel qui ne prend pas en charge le ProxyProtocol (comme MySQL ou PostgreSQL) afin de récupérer et de journaliser l'adresse IP du client.
+ Un schéma courant consiste à placer une instance HAProxy locale devant un logiciel qui ne prend pas en charge le ProxyProtocol (comme MySQL ou PostgreSQL), afin de récupérer et de journaliser l'adresse IP du client.
```


## configure-redirections.mdx

**50.**

```diff
- Il peut, à la place, renvoyer une redirection HTTP qui dirige le client vers une autre URL. Cela s'avère utile pour forcer la version HTTPS d'un site ou pour migrer un nom de domaine.
+ Il peut aussi, à la place, renvoyer une redirection HTTP qui dirige le client vers une autre URL. C'est utile pour forcer la version HTTPS d'un site ou pour migrer un nom de domaine.
```

**51.**

```diff
- Vous configurez la redirection sur un frontend par l'intermédiaire de son emplacement de redirection. La valeur doit respecter le format `<scheme>://<net_loc>/<path>;<params>?<query>#<fragment>`. Vous ne pouvez définir qu'une seule redirection par frontend.
+ La redirection se configure sur un frontend via son emplacement de redirection. La valeur doit respecter le format `<scheme>://<net_loc>/<path>;<params>?<query>#<fragment>`. Vous ne pouvez définir qu'une seule redirection par frontend.
```

**52.**

```diff
- Dans l'API OVHcloud, vous définissez la redirection via la propriété `redirectLocation` d'un frontend HTTP. Configurez-la sur un frontend nouveau ou existant, puis appliquez les modifications.
+ Dans l'API OVHcloud, la redirection se définit via la propriété `redirectLocation` d'un frontend HTTP. Configurez-la sur un frontend nouveau ou existant, puis appliquez les modifications.
```


## configure-server-farms.mdx

**53.**

```diff
- Les modifications que vous apportez aux fermes, aux serveurs ou aux méthodes d'équilibrage sont mises en attente jusqu'à ce que vous appliquiez explicitement la configuration. Jusque-là, le trafic en production continue d'utiliser la configuration précédente.
+ Les modifications apportées aux fermes, aux serveurs ou aux méthodes d'équilibrage sont mises en attente jusqu'à ce que vous appliquiez explicitement la configuration. D'ici là, le trafic en production continue d'utiliser la configuration précédente.
```

**54.**

```diff
- Les frontends, les fermes et les serveurs sont spécifiques au protocole (HTTP, TCP ou UDP) dans lequel ils sont définis. La compatibilité entre ces composants n'est possible qu'au sein d'un même protocole : un frontend UDP ne peut être associé qu'à une ferme UDP, de même qu'un frontend HTTP ne s'associe qu'à une ferme HTTP.
+ Les frontends, les fermes et les serveurs sont spécifiques au protocole (HTTP, TCP ou UDP) dans lequel ils sont définis. Ces composants ne peuvent s'associer qu'au sein d'un même protocole : un frontend UDP ne peut être associé qu'à une ferme UDP, tout comme un frontend HTTP ne s'associe qu'à une ferme HTTP.
```

**55.**

```diff
- La compatibilité entre ces composants n'est possible qu'au sein d'un même protocole
+ Ces composants ne peuvent s'associer qu'au sein d'un même protocole
```


## configure-smtp.mdx

**56.**

```diff
- Le SMTP étant un protocole basé sur TCP, vous procédez à l'aide d'une ferme de serveurs TCP et d'un frontend TCP en écoute sur le port 25.
+ Le SMTP étant un protocole basé sur TCP, vous utilisez pour cela une ferme de serveurs TCP et un frontend TCP en écoute sur le port 25.
```

**57.**

```diff
- Le SMTP fonctionne au-dessus de TCP : l'ensemble de la configuration utilise donc la famille TCP.
+ Le SMTP fonctionne au-dessus de TCP : toute la configuration s'effectue donc dans la famille TCP.
```

**58.**

```diff
- l'ensemble de la configuration utilise donc la famille TCP.
+ toute la configuration s'effectue donc dans la famille TCP.
```


## configure-ssl-certificates.mdx

**59.**

```diff
- C'est ce que l'on appelle la terminaison SSL. Gérer la terminaison sur le Load Balancer réduit la charge de vos serveurs backend et centralise la gestion des certificats, ce qui simplifie la maintenance et les mises à jour de sécurité.
+ C'est ce que l'on appelle la terminaison SSL. Gérer la terminaison sur le Load Balancer allège vos serveurs backend et centralise la gestion des certificats, ce qui simplifie la maintenance et les mises à jour de sécurité.
```

**60.**

```diff
- Une fois un certificat présent, vous sélectionnez un **profil de chiffrement** qui contrôle les versions de TLS et les suites de chiffrement négociées par le frontend.
+ Une fois un certificat en place, vous sélectionnez un **profil de chiffrement** qui détermine les versions de TLS et les suites de chiffrement négociées par le frontend.
```

**61.**

```diff
- La terminaison SSL s'inscrit dans le chemin de la requête de la manière suivante. Le client ouvre une connexion TLS vers le frontend, le Load Balancer déchiffre le trafic, et la requête est routée en clair (ou rechiffrée, selon votre configuration) vers la ferme de serveurs.
+ Voici comment la terminaison SSL s'insère dans le chemin de la requête. Le client ouvre une connexion TLS vers le frontend, le Load Balancer déchiffre le trafic, puis la requête est routée en clair (ou rechiffrée, selon votre configuration) vers la ferme de serveurs.
```


## configure-stickiness.mdx

**62.**

```diff
- | IP source | `IP Source` | Un hachage de l'adresse IP source du client est utilisé pour acheminer systématiquement chaque client vers le même serveur. Disponible sur les fermes HTTP et TCP. |
+ | IP source | `IP Source` | Le Load Balancer hache l'adresse IP source du client pour acheminer systématiquement chaque client vers le même serveur. Disponible sur les fermes HTTP et TCP. |
```


## configure-vrack.mdx

**63.**

```diff
- Ce guide vous accompagne tout au long du processus : attacher le Load Balancer à un vRack, déclarer un réseau privé (sous-réseau et plage NAT) afin que le Load Balancer connaisse la topologie de votre vRack, et créer des fermes de serveurs qui joignent les backends via leurs adresses IP privées.
+ Ce guide couvre l'ensemble de la procédure : attacher le Load Balancer à un vRack, déclarer un réseau privé (sous-réseau et plage NAT) pour que le Load Balancer connaisse la topologie de votre vRack, et créer des fermes de serveurs qui joignent les backends via leurs adresses IP privées.
```

**64.**

```diff
- Ce guide vous accompagne tout au long du processus
+ Ce guide couvre l'ensemble de la procédure
```

**65.**

```diff
- déclarer un réseau privé (sous-réseau et plage NAT) afin que le Load Balancer connaisse la topologie de votre vRack, et créer des fermes
+ déclarer un réseau privé (sous-réseau et plage NAT) pour que le Load Balancer connaisse la topologie de votre vRack, puis créer des fermes
```

**66.**

```diff
- Le Load Balancer utilise cette plage comme source de tout le trafic envoyé à vos serveurs backend ; ainsi, les serveurs ne voient que des adresses sources privées et n'ont pas besoin d'une exposition publique.
+ Le Load Balancer utilise cette plage comme source de tout le trafic envoyé à vos serveurs backend : les serveurs ne voient ainsi que des adresses sources privées et n'ont plus besoin d'être exposés publiquement.
```

**67.**

```diff
- Trois éléments de configuration relient le Load Balancer à vos backends privés. Premièrement, attachez le service Load Balancer au vRack. Deuxièmement, déclarez un réseau privé sur le Load Balancer depuis l'onglet <code className="action">Réseau</code> : cela lui indique dans quel sous-réseau résident vos serveurs et quelle plage d'IP NAT il peut utiliser comme source du trafic vers les backends. Troisièmement, liez chaque ferme de serveurs à ce réseau privé afin que ses serveurs soient adressés par leurs IP privées.
+ Trois éléments de configuration relient le Load Balancer à vos backends privés. D'abord, attachez le service Load Balancer au vRack. Ensuite, déclarez un réseau privé sur le Load Balancer depuis l'onglet <code className="action">Réseau</code> : vous lui indiquez ainsi dans quel sous-réseau résident vos serveurs et quelle plage d'IP NAT il peut utiliser comme source du trafic vers les backends. Enfin, liez chaque ferme de serveurs à ce réseau privé pour que ses serveurs soient adressés par leurs IP privées.
```

**68.**

```diff
- ainsi, les serveurs ne voient que des adresses sources privées et n'ont pas besoin d'une exposition publique.
+ les serveurs ne voient ainsi que des adresses sources privées et n'ont plus besoin d'être exposés publiquement.
```

**69.**

```diff
- Premièrement, attachez le service Load Balancer au vRack. Deuxièmement, déclarez un réseau privé sur le Load Balancer depuis l'onglet <code className="action">Réseau</code>
+ D'abord, attachez le service Load Balancer au vRack. Ensuite, déclarez un réseau privé sur le Load Balancer depuis l'onglet <code className="action">Réseau</code>
```

**70.**

```diff
- cela lui indique dans quel sous-réseau résident vos serveurs et quelle plage d'IP NAT il peut utiliser comme source du trafic vers les backends. Troisièmement, liez chaque ferme de serveurs à ce réseau privé afin que ses serveurs soient adressés par leurs IP privées.
+ vous lui indiquez ainsi dans quel sous-réseau résident vos serveurs et quelle plage d'IP NAT il peut utiliser comme source du trafic vers les backends. Enfin, liez chaque ferme de serveurs à ce réseau privé pour que ses serveurs soient adressés par leurs IP privées.
```


## configure-zones.mdx

**71.**

```diff
- Répartir le service sur plusieurs zones vous apporte deux bénéfices :
+ Répartir le service sur plusieurs zones présente deux avantages :
```

**72.**

```diff
- Répartir le service sur plusieurs zones vous apporte deux bénéfices
+ Répartir le service sur plusieurs zones présente deux avantages
```

**73.**

```diff
- > Travailler avec plusieurs zones revient généralement à travailler avec plusieurs régions OVHcloud, car la plupart des régions n'exposent qu'une seule zone de disponibilité.
+ > Utiliser plusieurs zones revient généralement à utiliser plusieurs régions OVHcloud, car la plupart des régions n'exposent qu'une seule zone de disponibilité.
```


## declare-an-incident.mdx

**74.**

```diff
- Avant de déclarer un incident, vérifiez que le problème n'est pas un problème de configuration que vous pouvez résoudre vous-même. La plupart des problèmes de serveur, de routage et de certificat se règlent au sein de votre propre configuration.
+ Avant de déclarer un incident, assurez-vous qu'il ne s'agit pas d'un problème de configuration que vous pouvez résoudre vous-même. La plupart des problèmes de serveur, de routage et de certificat se règlent directement dans votre configuration.
```

**75.**

```diff
- Les étapes ci-dessous vous aident à identifier la situation qui s'applique, à rassembler les bons éléments et à ouvrir une demande de suivi.
+ Les étapes ci-dessous vous aident à identifier la situation concernée, à rassembler les bons éléments et à ouvrir une demande de suivi.
```


## faq.mdx

**76.**

```diff
- Une ferme HTTP comprend le protocole HTTP et peut agir sur les requêtes, par exemple en lisant les en-têtes, en appliquant des routes ou en gérant la persistance basée sur les cookies.
+ Une ferme HTTP interprète le protocole HTTP et peut agir sur les requêtes, par exemple en lisant les en-têtes, en appliquant des routes ou en gérant la persistance basée sur les cookies.
```

**77.**

```diff
- Une ferme UDP fonctionne au même niveau de connexion/datagramme qu'une ferme TCP, mais transfère des datagrammes UDP, qui conviennent aux protocoles basés sur les datagrammes tels que DNS, VoIP, le jeu en ligne ou syslog.
+ Une ferme UDP opère au même niveau (connexion/datagramme) qu'une ferme TCP, mais transfère des datagrammes UDP, adaptés aux protocoles basés sur les datagrammes tels que DNS, VoIP, le jeu en ligne ou syslog.
```


## glossary.mdx

**78.**

```diff
- afin que des concepts comme les frontends, les fermes, les sondes et la persistance gardent une signification cohérente tout au long de votre travail de configuration.
+ afin que des concepts comme les frontends, les fermes, les sondes et la persistance gardent une signification cohérente d'un bout à l'autre de votre configuration.
```

**79.**

```diff
- La plupart des termes du Load Balancer décrivent l'une de trois choses : un objet que vous configurez (frontend, ferme, serveur), un comportement que vous appliquez au trafic (méthode d'équilibrage, persistance, route, sonde) ou une propriété de la plateforme sous-jacente (zone, anycast, vRack, terminaison SSL).
+ La plupart des termes du Load Balancer relèvent de l'une de trois catégories : un objet que vous configurez (frontend, ferme, serveur), un comportement que vous appliquez au trafic (méthode d'équilibrage, persistance, route, sonde) ou une propriété de la plateforme sous-jacente (zone, anycast, vRack, terminaison SSL).
```

**80.**

```diff
- La plupart des termes du Load Balancer décrivent l'une de trois choses
+ La plupart des termes du Load Balancer relèvent de l'une de trois catégories
```


## high-availability.mdx

**81.**

```diff
- - À travers plusieurs zones, le service peut être déployé de sorte qu'une zone entière puisse tomber en panne sans mettre le service hors ligne.
- - À travers les régions, le routage Anycast dirige chaque client vers le point d'entrée sain le plus proche et redirige le trafic hors d'un emplacement défaillant.
+ - Sur plusieurs zones, le service peut être déployé de sorte qu'une zone entière puisse tomber en panne sans mettre le service hors ligne.
+ - Entre les régions, le routage Anycast dirige chaque client vers le point d'entrée sain le plus proche et réachemine le trafic hors d'un emplacement défaillant.
```

**82.**

```diff
- La plupart des régions OVHcloud exposent une seule zone ; travailler avec plusieurs zones revient donc généralement à travailler avec plusieurs régions.
+ La plupart des régions OVHcloud exposent une seule zone : utiliser plusieurs zones revient donc généralement à utiliser plusieurs régions.
```

**83.**

```diff
- travailler avec plusieurs zones revient donc généralement à travailler avec plusieurs régions.
+ utiliser plusieurs zones revient donc généralement à utiliser plusieurs régions.
```

**84.**

```diff
- Le failover est le processus consistant à retirer une cible non saine de la rotation et à envoyer son trafic ailleurs.
+ Le failover consiste à retirer une cible non saine de la rotation et à rediriger son trafic ailleurs.
```

**85.**

```diff
- L'anti-affinité est le principe consistant à placer des composants redondants dans des domaines de défaillance distincts afin qu'une seule panne ne puisse pas en mettre plus d'un hors service.
+ L'anti-affinité consiste à placer des composants redondants dans des domaines de défaillance distincts, de sorte qu'une seule panne ne puisse pas en mettre plusieurs hors service.
```

**86.**

```diff
- le trafic est acheminé en priorité par la zone non-APAC en premier, même lorsque le service est hors service dans cette zone.
+ le trafic est acheminé en priorité par la zone non-APAC, même lorsque le service y est hors service.
```


## manage-via-control-panel.mdx

**87.**

```diff
- Vous gérez l'OVHcloud Load Balancer depuis un tableau de bord dédié dans l'<ManagerLink to="/">espace client OVHcloud</ManagerLink>. L'interface regroupe chaque partie du service dans des onglets et applique un modèle de configuration par étapes : la plupart des modifications sont enregistrées comme des modifications en attente et ne prennent effet qu'une fois que vous les appliquez.
+ L'OVHcloud Load Balancer se gère depuis un tableau de bord dédié dans l'<ManagerLink to="/">espace client OVHcloud</ManagerLink>. L'interface regroupe chaque partie du service dans des onglets et applique un modèle de configuration par étapes : la plupart des modifications sont enregistrées comme des modifications en attente et ne prennent effet qu'une fois appliquées.
```

**88.**

```diff
- Vous gérez l'OVHcloud Load Balancer depuis un tableau de bord dédié dans l'<ManagerLink to="/">espace client OVHcloud</ManagerLink>. L'interface regroupe chaque partie du service dans des onglets et applique un modèle de configuration par étapes
+ L'OVHcloud Load Balancer se gère depuis un tableau de bord dédié dans l'<ManagerLink to="/">espace client OVHcloud</ManagerLink>. L'interface regroupe chaque partie du service dans des onglets et applique un modèle de configuration par étapes
```

**89.**

```diff
- la plupart des modifications sont enregistrées comme des modifications en attente et ne prennent effet qu'une fois que vous les appliquez.
+ la plupart des modifications sont enregistrées comme des modifications en attente et ne prennent effet qu'une fois appliquées.
```

**90.**

```diff
- - Comprendre comment les modifications en attente sont mises en attente puis appliquées.
+ - Comprendre comment les modifications sont mises en attente puis appliquées.
```

**91.**

```diff
- Le tableau de bord s'ouvre sur la vue `Général`, qui résume le service : statut, adresses IP rattachées, zone de disponibilité et nombre de frontends, de fermes et de serveurs configurés. Les onglets situés en haut donnent accès à chaque zone configurable.
+ Le tableau de bord s'ouvre sur la vue `Général`, qui résume le service : statut, adresses IP rattachées, zone de disponibilité et nombre de frontends, de fermes et de serveurs configurés. Les onglets situés en haut donnent accès à chaque partie configurable.
```

**92.**

```diff
- Cette section explique comment le Load Balancer active vos modifications. Ce modèle est essentiel à comprendre, car la plupart des modifications ne prennent pas effet au moment où vous les enregistrez.
+ Cette section explique comment le Load Balancer active vos modifications. Ce modèle est essentiel à comprendre, car la plupart des modifications ne prennent pas effet dès leur enregistrement.
```

**93.**

```diff
- Cela vous permet de mettre en attente plusieurs modifications et de les activer ensemble en une seule opération atomique. La configuration active continue de traiter le trafic avec les paramètres précédents jusqu'à ce que vous appliquiez.
+ Vous pouvez ainsi regrouper plusieurs modifications et les activer ensemble en une seule opération atomique. La configuration active continue de traiter le trafic avec les paramètres précédents tant que vous n'avez pas appliqué les modifications.
```

**94.**

```diff
- Avant d'appliquer, vérifiez ce qui est en attente afin de n'activer que les modifications souhaitées.
+ Avant d'appliquer, vérifiez ce qui est en attente pour n'activer que les modifications souhaitées.
```

**95.**

```diff
- L'application pousse chaque modification en attente vers la configuration active en une seule opération.
+ L'application bascule chaque modification en attente vers la configuration active en une seule opération.
```


## monitor-server-health.mdx

**96.**

```diff
- L'état de santé reflète le résultat de la sonde définie sur la ferme. Sans sonde, le Load Balancer ne peut pas évaluer l'état des serveurs : le statut rapporté n'est donc pas pertinent.
+ L'état de santé reflète le résultat de la sonde définie sur la ferme. Sans sonde, le Load Balancer ne peut pas évaluer l'état des serveurs : le statut affiché n'est donc pas significatif.
```

**97.**

```diff
- le Load Balancer ne peut pas évaluer l'état des serveurs
+ le Load Balancer ne peut pas évaluer l'état des serveurs
```

**98.**

```diff
-  le statut rapporté n'est donc pas pertinent.
+  le statut affiché n'est donc pas significatif.
```


## order-load-balancer.mdx

**99.**

```diff
- Si vous ne disposez encore d'aucun service, la page `All Load Balancers` vous permet de démarrer une nouvelle commande. Cliquez sur le point d'entrée de commande pour ouvrir le tunnel.
+ Si vous ne disposez encore d'aucun service, la page `All Load Balancers` vous permet de démarrer une nouvelle commande. Cliquez sur le bouton de commande pour ouvrir le tunnel.
```

**100.**

```diff
- Le tunnel de commande vous guide dans la configuration de votre nouveau service. Sélectionnez les options qui correspondent à vos besoins.
+ Le tunnel de commande vous accompagne dans la configuration de votre nouveau service. Sélectionnez les options qui correspondent à vos besoins.
```


## prerequisites-and-limitations.mdx

**101.**

```diff
- Deux conséquences découlent de cette répartition et contraignent votre architecture :
+ Cette répartition a deux conséquences qui pèsent sur votre architecture :
```

**102.**

```diff
- Deux conséquences découlent de cette répartition et contraignent votre architecture
+ Cette répartition a deux conséquences qui pèsent sur votre architecture
```

**103.**

```diff
- Au-delà des quotas numériques, plusieurs contraintes de conception s'appliquent à chaque Load Balancer, quel que soit le plan. Tenez-en compte lors de la planification pour éviter d'avoir à retravailler votre configuration par la suite.
+ Outre les quotas numériques, plusieurs contraintes de conception s'appliquent à chaque Load Balancer, quel que soit le plan. Tenez-en compte dès la planification pour éviter d'avoir à retravailler votre configuration par la suite.
```

**104.**

```diff
- Les modifications que vous effectuez dans l'espace client ou via l'API sont mises en attente sous forme de changements en attente et ne prennent effet que lorsque vous les appliquez. Jusque-là, la configuration en cours d'exécution reste inchangée.
+ Les modifications que vous effectuez dans l'espace client ou via l'API sont mises en attente et ne prennent effet que lorsque vous les appliquez. Jusque-là, la configuration en cours d'exécution reste inchangée.
```

**105.**

```diff
- Une modification qui dépasserait un quota est rejetée lors de son déploiement, et non lors de sa rédaction.
+ Une modification qui dépasserait un quota est rejetée lors de son déploiement, et non au moment où vous la définissez.
```


## quickstart-http-https.mdx

**106.**

```diff
- Les changements de configuration ne sont effectifs qu'une fois que vous les appliquez (rafraîchissez) dans chaque zone de votre service. Cela vous permet de préparer un changement complexe et de le déployer en une seule étape. Si votre service s'étend sur plusieurs zones, appliquez la configuration à chaque zone.
+ Les changements de configuration ne sont effectifs qu'une fois appliqués (rafraîchis) dans chaque zone de votre service. Vous pouvez ainsi préparer un changement complexe et le déployer en une seule étape. Si votre service s'étend sur plusieurs zones, appliquez la configuration à chacune d'elles.
```

**107.**

```diff
- Activez éventuellement le HSTS. Avec le HSTS, les navigateurs utilisent le HTTPS pour chaque visite future, ce qui protège contre les attaques par rétrogradation.
+ Activez éventuellement le HSTS. Les navigateurs utilisent alors le HTTPS pour chaque visite ultérieure, ce qui protège contre les attaques par rétrogradation.
```


## quickstart-tcp.mdx

**108.**

```diff
- Ce guide vous accompagne dans le déploiement complet d'un Load Balancer TCP. Vous allez créer une ferme de serveurs TCP, attacher vos serveurs backend, ajouter une sonde TCP, exposer le service via un frontend TCP, appliquer la configuration et vérifier que le trafic atteint vos backends. L'exemple cible un service TCP classique tel que SMTP (port 25) ou une base de données, mais le même déroulé s'applique à tout protocole basé sur TCP.
+ Ce guide vous accompagne dans le déploiement complet d'un Load Balancer TCP. Vous allez créer une ferme de serveurs TCP, y attacher vos serveurs backend, ajouter une sonde TCP, exposer le service via un frontend TCP, appliquer la configuration et vérifier que le trafic atteint bien vos backends. L'exemple porte sur un service TCP classique comme SMTP (port 25) ou une base de données, mais le même déroulé s'applique à tout protocole reposant sur TCP.
```

**109.**

```diff
- - Ajouter une sonde TCP afin que le trafic n'atteigne que les backends sains.
+ - Ajouter une sonde TCP pour que le trafic n'atteigne que les backends sains.
```

**110.**

```diff
- L'ordre dans lequel vous créez les composants est important. La ferme de serveurs doit exister avant que vous puissiez lui attacher des serveurs, et la ferme doit exister avant que vous puissiez la définir comme ferme par défaut d'un frontend.
+ L'ordre dans lequel vous créez les composants a son importance. La ferme de serveurs doit exister avant que vous puissiez lui attacher des serveurs ou la définir comme ferme par défaut d'un frontend.
```

**111.**

```diff
- Un Load Balancer TCP opère au niveau de la couche 4 et transmet les connexions TCP brutes sans inspecter le contenu applicatif, ce qui le rend adapté à des protocoles tels que SMTP, les connexions à des bases de données ou tout service non HTTP.
+ Un Load Balancer TCP opère au niveau de la couche 4 : il transmet les connexions TCP brutes sans inspecter le contenu applicatif, ce qui convient à des protocoles comme SMTP, aux connexions à des bases de données ou à tout service non HTTP.
```

**112.**

```diff
- La ferme de serveurs répartit le trafic entre vos serveurs backend. Créez-la en premier, avant d'attacher le moindre serveur.
+ La ferme de serveurs répartit le trafic entre vos serveurs backend. Créez-la en premier, avant d'y attacher le moindre serveur.
```

**113.**

```diff
- 3. Renseignez les champs. Les champs obligatoires sont l'adresse IPv4 et le statut. Définissez le statut de sorte que le serveur soit actif et éligible à recevoir du trafic.
+ 3. Renseignez les champs. Les champs obligatoires sont l'adresse IPv4 et le statut. Réglez le statut pour que le serveur soit actif et puisse recevoir du trafic.
```

**114.**

```diff
- Une sonde permet au Load Balancer de détecter les backends qui ne répondent pas et de cesser de leur envoyer du trafic. Sans sonde, le Load Balancer risque de transmettre des connexions à un serveur hors service. Vous configurez la sonde au niveau de la ferme.
+ Une sonde permet au Load Balancer de détecter les backends qui ne répondent pas et de cesser de leur envoyer du trafic. Sans elle, le Load Balancer risque de transmettre des connexions à un serveur hors service. La sonde se configure au niveau de la ferme.
```

**115.**

```diff
- Les modifications apportées à votre Load Balancer ne sont pas actives tant que vous ne les avez pas appliquées dans chaque zone configurée. Cela vous permet de préparer une configuration complète et de ne l'activer que lorsque vous êtes prêt. Si votre service s'étend sur plusieurs zones, appliquez la configuration à chacune d'elles.
+ Les modifications apportées à votre Load Balancer ne sont actives qu'une fois appliquées dans chaque zone configurée. Vous pouvez ainsi préparer une configuration complète et ne l'activer que lorsque vous êtes prêt. Si votre service s'étend sur plusieurs zones, appliquez la configuration à chacune d'elles.
```

**116.**

```diff
- Si le problème persiste après ces vérifications, rassemblez les journaux de connexion et le statut de la sonde pertinents, puis consultez le guide
+ Si le problème persiste après ces vérifications, rassemblez les journaux de connexion et le statut de la sonde concernés, puis consultez le guide
```


## route-additional-ip.mdx

**117.**

```diff
- Une Additional IP est une adresse IP que vous pouvez basculer d'un service OVHcloud à un autre. La router vers le Load Balancer OVHcloud déplace le trafic existant vers le Load Balancer sans changer votre adresse IP publique et sans attendre la propagation DNS.
+ Une Additional IP est une adresse IP que vous pouvez basculer d'un service OVHcloud à un autre. La router vers le Load Balancer OVHcloud y bascule le trafic existant sans changer votre adresse IP publique ni attendre la propagation DNS.
```

**118.**

```diff
- - La router vers un **seul frontend**, de sorte qu'elle donne accès uniquement au service exposé par ce frontend. Vos autres frontends restent accessibles via l'adresse IP principale du Load Balancer.
- 
- Choisissez la portée qui correspond à votre migration : une IP à l'échelle du service pour remplacer une à une une adresse IP publique existante, ou une IP dédiée lorsque vous souhaitez qu'un frontend réponde sur sa propre adresse.
+ - La router vers un **seul frontend** : elle ne donne alors accès qu'au service exposé par ce frontend. Vos autres frontends restent accessibles via l'adresse IP principale du Load Balancer.
+ 
+ Choisissez la portée adaptée à votre migration : une IP à l'échelle du service pour remplacer une à une une adresse IP publique existante, ou une IP dédiée si vous voulez qu'un frontend réponde sur sa propre adresse.
```

**119.**

```diff
- - La router vers un **seul frontend**, de sorte qu'elle donne accès uniquement au service exposé par ce frontend. Vos autres frontends restent accessibles via l'adresse IP principale du Load Balancer.
+ - La router vers un **seul frontend** : elle ne donne alors accès qu'au service exposé par ce frontend. Vos autres frontends restent accessibles via l'adresse IP principale du Load Balancer.
```

**120.**

```diff
- une IP à l'échelle du service pour remplacer une à une une adresse IP publique existante, ou une IP dédiée lorsque vous souhaitez qu'un frontend réponde sur sa propre adresse.
+ une IP à l'échelle du service pour remplacer une à une une adresse IP publique existante, ou une IP dédiée si vous voulez qu'un frontend réponde sur sa propre adresse.
```

**121.**

```diff
- Cette portée rend l'Additional IP disponible pour tous les frontends du Load Balancer. Routez l'IP via l'API OVHcloud, puis vérifiez l'association.
- 
- Commencez par déplacer l'Additional IP vers le service Load Balancer :
+ Cette portée rend l'Additional IP disponible pour tous les frontends du Load Balancer. Routez l'IP via l'API OVHcloud, puis vérifiez l'association.
+ 
+ Commencez par déplacer l'Additional IP vers le service Load Balancer :
+ 
```

**122.**

```diff
- Cette portée rattache l'Additional IP à un seul frontend. L'IP donne alors accès exclusivement au service exposé par ce frontend, tandis que vos autres frontends restent accessibles via l'adresse IP principale du Load Balancer. Configurez une IP dédiée depuis l'API OVHcloud.
+ Cette portée rattache l'Additional IP à un seul frontend. L'IP ne donne alors accès qu'au service exposé par ce frontend, tandis que vos autres frontends restent accessibles via l'adresse IP principale du Load Balancer. Configurez une IP dédiée depuis l'API OVHcloud.
```


## security-best-practices.mdx

**123.**

```diff
- Il s'adresse aux architectes et aux opérateurs qui souhaitent appliquer des paramètres de sécurité cohérents et justifiables à leur configuration de Load Balancer, plutôt que de suivre une procédure unique étape par étape.
+ Il s'adresse aux architectes et aux opérateurs qui cherchent à appliquer des paramètres de sécurité cohérents et justifiés à leur Load Balancer, plutôt qu'à suivre une procédure unique étape par étape.
```

**124.**

```diff
- La centralisation du TLS concentre aussi le risque : un profil de chiffrement faible, un certificat expiré ou un frontend mal configuré affecte chaque backend situé derrière lui. Les recommandations ci-dessous décrivent comment maintenir ce point unique renforcé.
+ Mais centraliser le TLS concentre aussi le risque : un profil de chiffrement faible, un certificat expiré ou un frontend mal configuré affecte tous les backends situés derrière lui. Les recommandations ci-dessous expliquent comment garder ce point unique bien protégé.
```

**125.**

```diff
- La centralisation du TLS concentre aussi le risque :
+ Mais centraliser le TLS concentre aussi le risque :
```

**126.**

```diff
- un frontend mal configuré affecte chaque backend situé derrière lui. Les recommandations ci-dessous décrivent comment maintenir ce point unique renforcé.
+ un frontend mal configuré affecte tous les backends situés derrière lui. Les recommandations ci-dessous expliquent comment garder ce point unique bien protégé.
```

**127.**

```diff
- La terminaison TLS est le processus consistant à déchiffrer un flux chiffré entrant au niveau du Load Balancer avant de transmettre la requête en clair (ou rechiffrée) à un backend. La terminaison s'active sur un frontend : vous créez un frontend `HTTPS`, vous y attachez un certificat et vous sélectionnez la ferme de serveurs qui reçoit le trafic déchiffré.
+ La terminaison TLS consiste à déchiffrer un flux entrant au niveau du Load Balancer avant de transmettre la requête en clair (ou rechiffrée) à un backend. Elle s'active sur un frontend : créez un frontend `HTTPS`, attachez-y un certificat et sélectionnez la ferme de serveurs qui reçoit le trafic déchiffré.
```

**128.**

```diff
- La terminaison TLS est le processus consistant à déchiffrer un flux chiffré entrant au niveau du Load Balancer avant de transmettre la requête en clair (ou rechiffrée) à un backend. La terminaison s'active sur un frontend
+ La terminaison TLS consiste à déchiffrer un flux entrant au niveau du Load Balancer avant de transmettre la requête en clair (ou rechiffrée) à un backend. Elle s'active sur un frontend
```

**129.**

```diff
-  vous créez un frontend `HTTPS`, vous y attachez un certificat et vous sélectionnez la ferme de serveurs qui reçoit le trafic déchiffré.
+  créez un frontend `HTTPS`, attachez-y un certificat et sélectionnez la ferme de serveurs qui reçoit le trafic déchiffré.
```

**130.**

```diff
- Un certificat prouve l'identité du service auprès des clients qui s'y connectent et fournit le matériel de clé utilisé pour négocier la session.
+ Un certificat prouve l'identité du service auprès des clients qui s'y connectent et fournit le matériel cryptographique servant à négocier la session.
```

**131.**

```diff
- Une fois la terminaison TLS effectuée, la connexion vers le backend provient du Load Balancer, et non du client. Sans configuration supplémentaire, les serveurs backend voient l'adresse IP du Load Balancer comme source de chaque requête. Deux mécanismes préservent les informations d'origine du client :
+ Une fois la terminaison TLS effectuée, la connexion vers le backend provient du Load Balancer, et non du client. Sans configuration supplémentaire, les serveurs backend voient l'adresse IP du Load Balancer comme source de chaque requête. Deux mécanismes permettent de préserver les informations d'origine du client :
```

**132.**

```diff
- **À faire :** assurez la terminaison TLS sur le Load Balancer pour les services web publics. Cela centralise la gestion des certificats, réduit la charge cryptographique du backend et vous permet d'appliquer une politique de chiffrement cohérente en périphérie. Lorsque vous créez le frontend `HTTPS`, configurez également la redirection HTTPS afin que les requêtes en clair soient redirigées plutôt que servies en HTTP.
+ **À faire :** assurez la terminaison TLS sur le Load Balancer pour les services web publics. Vous centralisez ainsi la gestion des certificats, réduisez la charge cryptographique du backend et pouvez appliquer une politique de chiffrement cohérente en périphérie. Lorsque vous créez le frontend `HTTPS`, configurez aussi la redirection HTTPS pour que les requêtes en clair soient redirigées plutôt que servies en HTTP.
```

**133.**

```diff
-  assurez la terminaison TLS sur le Load Balancer pour les services web publics. Cela centralise la gestion des certificats, réduit la charge cryptographique du backend et vous permet d'appliquer une politique de chiffrement cohérente en périphérie. Lorsque vous créez le frontend `HTTPS`, configurez également la redirection HTTPS afin que les requêtes en clair soient redirigées plutôt que servies en HTTP.
+  assurez la terminaison TLS sur le Load Balancer pour les services web publics. Vous centralisez ainsi la gestion des certificats, réduisez la charge cryptographique du backend et pouvez appliquer une politique de chiffrement cohérente en périphérie. Lorsque vous créez le frontend `HTTPS`, configurez aussi la redirection HTTPS pour que les requêtes en clair soient redirigées plutôt que servies en HTTP.
```

**134.**

```diff
-  laisser un frontend `HTTP` accessible en parallèle d'un frontend `HTTPS` sans redirection. Les points d'accès en clair exposent les identifiants et les jetons de session pendant le transit.
+  laisser un frontend `HTTP` accessible en parallèle d'un frontend `HTTPS` sans redirection. Les points d'accès en clair exposent les identifiants et les jetons de session pendant leur transit.
```

**135.**

```diff
-  choisir un profil permissif pour accueillir un petit nombre de clients obsolètes. Un seul profil faible abaisse la sécurité de chaque backend situé derrière le frontend.
+  choisir un profil permissif pour accommoder une poignée de clients obsolètes. Un profil faible abaisse la sécurité de tous les backends situés derrière le frontend.
```

**136.**

```diff
-  laisser un certificat expirer. Un certificat expiré entraîne des échecs de connexion pour chaque client du frontend concerné. Évitez de réutiliser une même clé privée pour des services sans rapport entre eux.
+  laisser un certificat expirer. Un certificat expiré provoque des échecs de connexion pour tous les clients du frontend concerné. Évitez également de réutiliser une même clé privée pour des services sans rapport entre eux.
```

**137.**

```diff
-  baser le contrôle d'accès ou la détection d'abus sur l'IP source vue par le backend sans avoir d'abord activé l'un de ces mécanismes — sans quoi chaque requête semblerait provenir du Load Balancer.
+  baser le contrôle d'accès ou la détection d'abus sur l'IP source vue par le backend sans avoir d'abord activé l'un de ces mécanismes — faute de quoi chaque requête semblera provenir du Load Balancer.
```

**138.**

```diff
-  supposer qu'une modification est active avant qu'elle ne soit appliquée. Tant que la configuration n'est pas appliquée, le Load Balancer en cours d'exécution conserve ses paramètres précédents.
+  supposer qu'une modification est active avant de l'avoir appliquée. Tant que la configuration n'est pas appliquée, le Load Balancer en service conserve ses paramètres précédents.
```

**139.**

```diff
- Un certificat Let's Encrypt gratuit est le point de départ recommandé lorsque votre domaine pointe vers votre Load Balancer. OVHcloud le renouvelle automatiquement, ce qui supprime la cause la plus fréquente des interruptions TLS.
+ Un certificat Let's Encrypt gratuit est le point de départ recommandé lorsque votre domaine pointe vers votre Load Balancer. OVHcloud le renouvelle automatiquement, ce qui élimine la cause la plus fréquente des interruptions TLS.
```


## troubleshooting.mdx

**140.**

```diff
- Ce guide vous aide à diagnostiquer et résoudre les problèmes les plus courants du service OVHcloud Load Balancer. Chaque scénario suit le même schéma : le symptôme que vous observez, la manière de confirmer la cause et la manière de la corriger.
+ Ce guide vous aide à diagnostiquer et résoudre les problèmes les plus courants du service OVHcloud Load Balancer. Chaque scénario suit le même schéma : le symptôme observé, comment en confirmer la cause et comment la corriger.
```

**141.**

```diff
- Il reçoit les requêtes des clients sur un frontend et les répartit entre les serveurs d'une ferme, en fonction de l'algorithme de répartition et des résultats des sondes.
+ Il reçoit les requêtes des clients sur un frontend et les répartit entre les serveurs d'une ferme, selon l'algorithme de répartition et les résultats des sondes.
```

**142.**

```diff
-  le symptôme que vous observez, la manière de confirmer la cause et la manière de la corriger.
+  le symptôme observé, comment en confirmer la cause et comment la corriger.
```

**143.**

```diff
- Utilisez la liste de contrôle de diagnostic ci-dessous pour identifier votre symptôme, puis passez directement à la section correspondante. Si aucune des résolutions ne s'applique, suivez les étapes d'escalade à la fin de ce guide.
+ Servez-vous de la liste de contrôle ci-dessous pour identifier votre symptôme, puis passez directement à la section correspondante. Si aucune résolution ne s'applique, suivez les étapes d'escalade en fin de guide.
```

**144.**

```diff
- - Un serveur est retiré de la rotation lorsque sa sonde échoue. Le trafic continue d'être acheminé vers les serveurs sains restants.
- - Les modifications de configuration ne sont pas actives tant que vous ne les avez pas appliquées. Tant que la modification n'est pas déployée, le Load Balancer continue de servir la configuration précédente.
+ - Un serveur est retiré de la rotation lorsque sa sonde échoue. Le trafic continue alors d'être acheminé vers les serveurs sains restants.
+ - Les modifications de configuration ne deviennent actives qu'une fois appliquées. Tant qu'une modification n'est pas déployée, le Load Balancer continue de servir la configuration précédente.
```

**145.**

```diff
- Un serveur est marqué DOWN lorsque sa sonde échoue. Le Load Balancer cesse alors de lui envoyer du trafic et redistribue la charge entre les serveurs restants de la ferme.
+ Un serveur passe DOWN lorsque sa sonde échoue. Le Load Balancer cesse alors de lui envoyer du trafic et redistribue la charge entre les serveurs restants de la ferme.
```

**146.**

```diff
- - La capacité du backend est réduite alors même que le serveur fonctionne.
+ - La capacité du backend diminue alors même que le serveur fonctionne.
```

**147.**

```diff
- Vous pouvez aussi, dans l'<ManagerLink to="/">espace client OVHcloud</ManagerLink>, ouvrir l'onglet `Fermes`, sélectionner la ferme et lire le statut sur la ligne de chaque serveur. Cliquez sur le texte du statut, ou sur le bouton <code className="action">...</code> suivi de <code className="action">Voir le statut</code>, pour ouvrir la vue détaillée.
+ Vous pouvez aussi, dans l'<ManagerLink to="/">espace client OVHcloud</ManagerLink>, ouvrir l'onglet `Fermes`, sélectionner la ferme et lire le statut sur la ligne de chaque serveur. Pour ouvrir la vue détaillée, cliquez sur le texte du statut, ou sur le bouton <code className="action">...</code> suivi de <code className="action">Voir le statut</code>.
```

**148.**

```diff
- 2. Vérifiez que la définition de la sonde correspond à ce qu'attend le backend. Pour une sonde HTTP, vérifiez la méthode de requête, le chemin de l'URL et le code de réponse attendu. Un backend renvoyant `301`, `403` ou `404` sur le chemin de la sonde est considéré comme une vérification en échec.
+ 2. Vérifiez que la définition de la sonde correspond à ce qu'attend le backend. Pour une sonde HTTP, contrôlez la méthode de requête, le chemin de l'URL et le code de réponse attendu. Un backend qui renvoie `301`, `403` ou `404` sur le chemin de la sonde fait échouer la vérification.
```

**149.**

```diff
- Une réponse `503` est renvoyée par le Load Balancer lui-même, et non par votre backend. Elle indique que le Load Balancer a reçu la requête mais ne disposait d'aucun serveur disponible pour la traiter.
+ Une réponse `503` provient du Load Balancer lui-même, et non de votre backend. Elle indique qu'il a bien reçu la requête, mais qu'aucun serveur n'était disponible pour la traiter.
```

**150.**

```diff
- - **Aucun serveur sain dans la ferme cible.** Tous les serveurs de la ferme sont DOWN, il n'y a donc nulle part où acheminer la requête. Vérifiez l'état de santé de chaque serveur comme décrit dans [Serveur signalé DOWN](#server-down).
- - **Aucune route ne correspond à la requête.** Le frontend n'a pas de ferme par défaut et aucune route HTTP ne correspond à la requête entrante : le Load Balancer n'a donc aucune destination.
+ - **Aucun serveur sain dans la ferme cible.** Tous les serveurs de la ferme sont DOWN : il n'y a donc nulle part où acheminer la requête. Vérifiez l'état de santé de chaque serveur comme décrit dans [Serveur signalé DOWN](#server-down).
+ - **Aucune route ne correspond à la requête.** Le frontend n'a pas de ferme par défaut et aucune route HTTP ne correspond à la requête entrante : le Load Balancer n'a donc aucune destination où l'envoyer.
```

**151.**

```diff
- Les problèmes TLS se manifestent par des échecs de liaison, des avertissements de certificat dans le navigateur ou des frontends HTTPS qui ne répondent pas alors que le HTTP fonctionne.
+ Les problèmes TLS se manifestent par des échecs de liaison, des avertissements de certificat dans le navigateur ou des frontends HTTPS qui ne répondent pas alors que le HTTP, lui, fonctionne.
```

**152.**

```diff
- Les modifications apportées aux fermes, aux serveurs, aux frontends, aux routes ou aux certificats sont préparées mais ne deviennent actives qu'une fois la configuration déployée. C'est de loin la raison la plus courante pour laquelle une modification « reste sans effet ».
+ Les modifications apportées aux fermes, aux serveurs, aux frontends, aux routes ou aux certificats sont préparées, mais ne deviennent actives qu'une fois la configuration déployée. C'est de loin la première raison pour laquelle une modification semble « rester sans effet ».
```

**153.**

```diff
- aux certificats sont préparées mais ne deviennent actives qu'une fois la configuration déployée. C'est de loin la raison la plus courante pour laquelle une modification
+ aux certificats sont préparées, mais ne deviennent actives qu'une fois la configuration déployée. C'est de loin la première raison pour laquelle une modification semble
```

**154.**

```diff
- une modification semble « reste sans effet ».
+ une modification semble « rester sans effet ».
```

**155.**

```diff
- reste sans effet
+ rester sans effet
```

**156.** _(was edits 156–159 — the agent used temporary `PLACEHOLDERXYZ` / `ZZZ` anchors while rewording this sentence and removed them in a follow-up cleanup; they are NOT in the guide. Net change:)_

```diff
- C'est de loin la première raison pour laquelle une modification semble « reste sans effet ».
+ C'est de loin la première raison pour laquelle une modification paraît rester sans effet.
```

**160.**

```diff
- Un statut indiquant un rechargement ou un déploiement en attente signifie qu'une modification de configuration est préparée mais pas encore active.
+ Un statut indiquant un rechargement ou un déploiement en attente signifie qu'une modification de configuration est préparée, mais pas encore active.
```

**161.**

```diff
- Effectuez le déploiement pendant une fenêtre de maintenance si vous êtes sensible aux courts événements de rechargement, et appliquez les modifications liées ensemble plutôt qu'une par une.
+ Effectuez le déploiement pendant une fenêtre de maintenance si vous êtes sensible à ces brèves interruptions, et regroupez les modifications liées plutôt que de les appliquer une par une.
```


## what-is-load-balancer.mdx

**162.**

```diff
- …quels éléments de base vous assemblez pour le configurer.
+ …quels éléments de base vous devez assembler pour le configurer.
```

**163.**

```diff
- …le Load Balancer constitue la solution adaptée.
+ …le Load Balancer est le bon choix.
```

**164.**

```diff
- Comprendre chacun d’eux et la façon dont ils s’articulent constitue le socle de toute tâche de configuration.
+ …est la base de toute tâche de configuration.
```

**165.**

```diff
- Les situations suivantes indiquent que le service est l’outil approprié.
+ Les situations suivantes sont autant de cas où il est pertinent.
```


---
Total: 165 edits across 34 files.
