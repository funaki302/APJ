claude --resume 606a469b-c5c7-4fe4-bea5-b6c3f60ec818

Prompt : 
La fonctionnalite : Reduction automatiquematique du prix a payer lors d'un facture via un avoir .
scenario : - le client a achete un produit a un somme de 20000Ar mais il a un avoir de 5000Ar. Le systeme doit automatiquement reduire le montant a payer a 15000Ar lors de la generation de la facture.
           - si il a un avoir de 10000Ar alors que il a achete un produit de 2000Ar il lui restera un avoir de 8000Ar pour les prochains achats.
           - jusqu'a ce que le montant de l'avoir soit epuisé, le systeme doit continuer a reduire le montant a payer lors des prochaines factures jusqu'a ce que l'avoir soit completement utilise.

donc lors de la saisie d'une facture, le systeme doit verifier si le client a un avoir disponible et appliquer automatiquement la reduction correspondante sur le montant total de la facture. Si le montant de l'avoir est superieur au montant de la facture, le systeme doit calculer le solde restant de l'avoir pour les prochains achats.
NB : n'oublie de faire les ecritures dans la bases de donnees lors de la vise. 

et puis je voudrais un bouton reinitialiser donner . pour effacer les avoirs et les factures pour repartir a zero et je veux aussi effacer les clients.
attetion je veux seulement effacer les clients et les avoirs et les factures mais pas les produits. mais pas les produit ou les choses importantes 


