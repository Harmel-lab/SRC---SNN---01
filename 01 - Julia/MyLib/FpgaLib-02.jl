##########################################################
## librairie - Modélisation équations pour le spiking et##
##             le bursting pour implémentation FPGA     ##
##########################################################
##                                                      ##
## Mise à l'échelle x1000 -> travailler 16bits entier   ##
##                                                      ##
## Fonction Frelu                                       ##
##   fonction de transormation d'une tanh -> linéaire   ##
##                                                      ##
## Fonction NeFsrc                                      ##
##   fonction de génération de spike suivant un modèle  ##
##   de feedback négatif et positif (idée de base SRC)  ##
##                                                      ##
##                Pascal Harmeling 2023 - Uliège        ##
##########################################################
##                         VERSION 3                    ##
##########################################################
## Version 1 - 24/10/2023                               ##
##      - implémentation de Frelu                       ##
##      - implémentation de NeFsrc!                     ##
## Version 2 - 21/12/2024                               ##
##      - Correction importante dans la formule H       ##
##        le bias doit être aussi multiplié par 2       ##
##      - simplification de l'analyse de hs             ##
## Version 3 - 31/12/2024                               ##
##      - Correction de la fonction Bursting suite à    ##
##        la modification de la fonction importante de H## 
## Version 4 - 01/09/2025                               ##
##      - simplification des fonctions                  ##
##           Frelu5 -> Frelu6                           ##
##           NeSRC3Fpga4 -> NeSRC3Fpga5                 ##
##########################################################

# --------------------------------------------------------------------------------------------------
# -----------------------------------Fonction Tanh -------------------------------------------------
# --------------------------------------------------------------------------------------------------
# fonction retourne la valeur du relu avec staturation [-1000...+1000] pente 0.75 - BIN 16bits entier
# - Idem que Frelu mais encore plus proche de bin FPGA -> on arrondi sur 6*x et décalage vers la droite du int obtenu
# - Idem Frelu2 mais on permutte la division et la multiplication et on reduit 6/8 par 3/4
# - Idem Frelu3 mais suppresion des opérateur '1000'
# validé le 19/12/23
# - On permutte l'opération >>2 et *3 pour augmenter la précision
# - ajout du round inbt16
# validé le 30/12/23
# - Idem Frelu4 mais suppression de la multiplication
# - Idem suppression du round devenu inutile
# validé le 09/01/2024
# - Suppression de  round -> attention entre floor et ceil :: Faire un test de signe
# - remplacement x*2 par x<<1
function Frelu6(x::Int16)
	tmpx::Int32=x
	y::Int16=((tmpx<<1)+tmpx)>>2 #y::Int16=( x>0 ? floor(((tmpx<<1)+tmpx)>>2) : ceil(((tmpx<<1)+tmpx)>>2) )
    if (y>1023) y=1023 end
    if (y<-1024) y=-1024 end
   return y
end

# --------------------------------------------------------------------------------------------------
# -----------------------------------Fonction Principale -------------------------------------------
# --------------------------------------------------------------------------------------------------
# - L'objectif est d'arriver à réduire au maximum la taille des mots de calcul.
# - utilisation de frelu6 -> reduction des opérations
# - suppression des Int16, Int32 et round dans le calcul de fhst
# - Comme pour Frelu6 -> correction floor ou ceil suivant signe de ((nhst - nht) * zst)>>10)
function NeSRC3Fpga5!(incur::Int16,nht::Int16,nhst::Int16,param)
    #passage des parametres
	bias::Int16=0
	zmax::Int16=0
	zmin::Int16=0
	bias,zmax,zmin	= param
	
	fht::Int16=0
	fhst::Int16=0
	
	#calcul le cycle de zst
    if nht<500 
        zst =zmax # CONSTANTE SUPPRESSION DE LA DEPENDANCE A H[T]
    else zst=zmin
    end
	
    #calcul fonction H en [t+1]
	fht = Frelu6(incur + (nht - (nhst<<2)+ bias)<<1)

	if (fht>1023) fht=1023 
	elseif (fht<-1024) fht=-1024
	end
	
    #calcul fonction Hs en [t+1]
	# Théoriquement -> fhst = zst*nhst + (1-zst)*nht si on distribue 
	tmpfhst::Int32 = (nhst - nht) #Int32
	tmpfhst= (tmpfhst * zst)>> 10
	fhst = nht + tmpfhst #( tmpfhst>0 ? floor(tmpfhst) : ceil(tmpfhst))

	#limiteur de seuil HST
    if (fhst>1023) fhst=1023
	elseif fhst<-800 fhst=-800
	end

    return fht, fhst, zst
end
