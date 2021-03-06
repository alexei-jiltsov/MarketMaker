
# Funktciia resheniia uravneniia HJB-QVI metodom obratnoi` induktcii
# plt - struktura, v kotoroi` opredeleny` osnovny`e peremenny`e i politiki
# plt.T - chislo vremenny`kh tochek rascheta, plt.S - chislo znachenii` spreda (=3)
# plt.F- chislo tochek rascheta disbalansa ob``ema, plt.Y - kolichestvo znachenii` otkry`toi` pozitcii
# plt.dF - shag velichiny` disbalansa ob``emov, plt.Fmax - modul` maksimal`nogo znacheniia disbalansa
# plt.ticksize - minimal`ny`i` shag ceny`, plt.comiss - birzhevaia komissiia
# plt.w - massiv znacheniia chislennoi` funktcii vladeniia
# plt.polmk - bulevy`i` massiv, opredeliaiushchii`, kakaia politika budet ispol`zovana pri tekushchikh znacheniiakh [t,y,f,s]
# esli true - limitny`e ordera, false - market ordera
# plt.thtkq - massiv ob``emov market orderov pri dei`stvii politiki market orderov
# plt.thmka, plt.thmkb - massiv znachenii` 0 (vy`stavlenie na luchshuiu cenu) ili 1 (vy`stavlenie na shag luchshe luchshei` ceny`)
# pri dei`stvii politiki limitny`kh orderov
# maxlot - absoliutnoe maksimal`noe znachenie otkry`toi` pozitcii

SolveBackwardInduction<-function( maxlot=5)
{   
    # Massiv znachenii` funktcii vladeniia
    # Dvigaemsia vniz po vremennoi` setke
    for (t in obMPdf$NT:1)
    {
        
        
        #Dvigaemsia po setke znacheniia spreda
        for (s in seq(along.with=obMPdf$SS))
        {
            # Opredeliaem massiv vektorov operatora L (massiv- po vsem znacheniiam otkry`toi` pozitcii,
            #vektor operatora - po vsem znacheniiam disbalansa)
            L <- matrix(data=0,nrow=obMPdf$NY, ncol=obMPdf$NF)
            
            #Dvigaemsia po setke otkry`ty`kh znachenii`
            for (y in seq(along.with=obMPdf$YY))
            {
                #Dvigaemsia po setke disbalansa ob``emov
                for (f in seq(along.with=obMPdf$FF))
                {
                    #Pervy`i` shag - vy`chislenie funktcii vladeniia w v konechny`i` moment vremeni T
                    if (t == obMPdf$NT) 
                        w[y, f,s] <<- -abs(obMPdf$YY[y]) * (obMPdf$SS[s] * obMPdf$deltaTick / 2 + obMPdf$eps)
                    else
                    {
                        #V ostal`ny`e momenty` vremeni nahodim znacheniia vektorov L (poka bez umnozheniia na 
                        # differentcial`ny`e matritcy` v pervoi` chasti vy`razheniia dlia L)
                        
                        L[y,f] = LV(y, f, s, t)
                    }
                    
                }
                if (t < obMPdf$NT)
                {
                    #Peremnozhenie matrichnoi` chasti i vektorov L, poluchenny`kh vy`she, v rezul`tate poluchaem
                    # polnost`iu rasschitanny`e vektora L. plt.rmatrix - matrichnaia chast`
                    L[y,]<-plt.Lmatrix %*%  L[y,]
                }

            }
            #Vy`chislenie vy`razheniia M*L dlia opredeleniia politiki market orderov
            if (t <obMPdf$NT)
            {
                #Dvigaemsia po setke otkry`toi` pozitcii
                for (y in seq(along.with=obMPdf$YY))
                {
                    #Dvigaemsia po setke disbalansa ob``emov
                    for (f in seq(along.with=obMPdf$FF))
                    {
                        #Maksimal`noe znachenie kontraktov, dopustimoe v market ordere na dannom shage
                        dzmax = min(obMPdf$NY-y, maxlot)
                        ML = -1000000
                        MLTemp=0
                        #Dvigaemsia po setke ob``ema market ordera
                        for (dz in seq(max(-y, -maxlot),dzmax,by=1))
                        {
                            #Vy`chislenie operatora M*L dlia kazhdogo znacheniia ob``ema market ordera
                            MLTemp=L[max(y + dz,1), f] - abs(dz) * (obMPdf$SS[s] * obMPdf$deltaTick / 2 + obMPdf$eps)
                            if( MLTemp> ML)
                            {
                                ML = MLTemp
                                #Zanesenie v politiku market orderov znacheniia ob``ema
                                plt.thtkq[t, y, f,s] <<- dz

                            }
                        }
                        #Esli operator M*L bol`she operatora L pri vsekh ishodny`kh parametrakh, vy`biraetsia politika
                        #market orderov
                        if (ML >  L[y,f])
                        {
                            #Znacheniiu funktcii vladeniia w prisvaivaetsia znachenie operatora M*L
                            w[y,f,s] <<- ML
                            plt.polmk[t,y,f,s] <<- FALSE
                        }
                        # Inache - politika limitny`kh orderov
                        else
                        {
                            #Znacheniiu funktcii vladeniia prisvaivaetsia znachenie operatora L
                            w[y,f,s] <<- L[y,f]
                            plt.polmk[t, y,f,s]  <<- TRUE
                        }
                        #DEBUG
                        print(paste("plt.polmk",plt.polmk[t, y,f,s], t, y, f, s))
                    }
                }
            }
        }
    }
#     assign("w", w, envir = .GlobalEnv)
#     assign("plt.thtkq",plt.thtkq, envir = .GlobalEnv)
#     assign("plt.polmk", plt.polmk, envir = .GlobalEnv)
#     assign("plt.thmkb", plt.thmkb, envir = .GlobalEnv)
#     assign("plt.thmka", plt.thmka, envir = .GlobalEnv)
    
}

#Funktciia vy`chisleniia znacheniia operatora L, bez peremnozheniia na matrichnuiu chast`
LV<-function(y,f, s, t){
    #Vy`chislenie znachenii` funktcii veroiatnosti skachkov ceny` na polshaga i shag psi1,2, s koe`ffitcientami beta1,2
    psi1res = 1/(1+exp(-obMPdf$beta1*obMPdf$FF[f]))
    psi2res = 1/(1+exp(-obMPdf$beta2*obMPdf$FF[f]))
    #Vy`chislenie matozhidaniia izmeneniia srednei` ceny`, plt.lj1,plt.lj2 - intensivnosti skachkov ceny`
    Edp = obMPdf$lambdaJ1 * (obMPdf$deltaTick / 2) * (2 * psi1res - 1) + obMPdf$lambdaJ2 * obMPdf$deltaTick * (2 * psi2res - 1)
    #Vy`chislenie operatora vozdei`stviia spreda na funktciiu vladeniia, plt.ro - matritca perehodov sostoianii` spreda
    Ls = 0
    for (j in seq( 1, nrow(obMPdf$roS)))
    {
        Ls =Ls+ (w[y,f, j] - w[y,f,s]) * obMPdf$roS[s,j]
    }
    #lambdaS - intensivnost` skachkov spreda
    Ls = obMPdf$lambdaS * Ls
    #Vy`chislenie matozhidaniia srednekvadratichnogo izmeneniia ceny`
    Edpp = 0.25 * obMPdf$lambdaJ1 + obMPdf$lambdaJ2
    
    gv = -10000000
    thmax = 1
    
    if (s == 1) thmax = 0
    gvtemp = 0
    #Vy`chislenie znachenii` veroiatnosti vziatiia limitny`kh orderov v ocheredi zaiavok h(f)
    #plt.ch - koe`ffitcient v formule dlia veroiatnosti h(f)
    hresp =  1/(1+exp(-(obMPdf$dzeta0+obMPdf$dzeta1*obMPdf$FF[f])))
    hresm =  1/(1+exp(-(obMPdf$dzeta0+obMPdf$dzeta1*(-obMPdf$FF[f]))))
    
    #Vy`chislenie slagaemy`kh ga i gb v vy`razhenii dlia operatora L, thmax - maksimal`noe znachenie, kotoroe prinimaet
    # politika dlia limitny`kh orderov - 1
    for (i in 0:thmax)
    {
        for (k in 0:thmax)
        {
            
            gvtemp = (i * obMPdf$lambdaMA + (1 - i) * obMPdf$lambdaMA * hresp) * 
                (w[min(y + 1, obMPdf$NY), f, s] - w[y,f,s] + obMPdf$SS[s] * obMPdf$deltaTick/2 - obMPdf$deltaTick*i)+
                (k*obMPdf$lambdaMB + (1 - k) * obMPdf$lambdaMB * hresm) * 
                (w[max(y - 1, 1), f,s]-w[y,f,s] +  obMPdf$SS[s] * obMPdf$deltaTick/ 2 - obMPdf$deltaTick* k)

            
            #Zanesenie znacheniia 0 ili 1 v politiku limitny`kh orderov
            if (gvtemp > gv)
            {
                gv = gvtemp
                plt.thmkb[t, y,f,s] <<- i 
                plt.thmka[t,y,f,s] <<- k
                

                
            }
        }
    }
    #Vy`chislenie znacheniia operatora L (bez umnozheniia na matrichnuiu chast`)
    #plt.dt- shag vremeni, plt.gamma - mera riska
    lv = w[y,f,s] + obMPdf$deltat * obMPdf$YY[y] * Edp + obMPdf$deltat * Ls - 
        obMPdf$deltat * obMPdf$gamma * obMPdf$YY[y]^2* Edpp + obMPdf$deltat * gv
    
    return(lv)
}


#Vy`chislenie matrichnoi` chasti vy`razheniia operatora L
SolveLMatrix<-function()
{
    
    # D2 [1,-2,1]  ν(t, y, fj+1, s) − 2ν(t, y, fj, s) + ν(t, y, fj−1, s)
    # D1 [0,-1,1] −ν(t,y,fj ,s)+ν(t,y,fj+1,s) if fj < 0
    #    [-1,1,0] −ν(t,y,fj−1,s)+ν(t,y,fj ,s) if fj ≥ 0
    uu<-c(1,-2,1, rep(0,obMPdf$NF-2))
    uu<-rep(uu,obMPdf$NF+1)
    uu<-uu[-1]
    uu<-uu[1:obMPdf$NF^2]
    D2<-matrix(uu, ncol=obMPdf$NF, nrow=obMPdf$NF, byrow=TRUE)
    D2<-D2/obMPdf$deltaF^2
    
    uun<-c(0,-1,1, rep(0,obMPdf$NF-2))
    uun<-rep(uun,obMPdf$NF+1)
    uun<-uun[-1]
    uun<-uun[1:(((obMPdf$NF-1)/2)*obMPdf$NF)]#obMPdf$NF^2]
    
    uup<-c(-1,1,0, rep(0,obMPdf$NF-2))
    uup<-rep(uup,obMPdf$NF+1)
    uup<-uup[-1]
    uup<-uup[(((obMPdf$NF-1)/2)*obMPdf$NF+1):(obMPdf$NF^2)]
    uu<-c(uun,uup)

    D1<-matrix(uu, ncol=obMPdf$NF, nrow=obMPdf$NF, byrow=TRUE)
    D1<-D1/obMPdf$deltaF
    
    #Differentcial`ny`e matritcy` D1,2 i matritca identichnosti I.
    #D1 = matrix(data=0,nrow=obMPdf$NF, ncol= obMPdf$NF)
    #D2 = matrix(data=0,nrow=obMPdf$NF, ncol= obMPdf$NF)
    I = diag(obMPdf$NF)
    LM = matrix(nrow=obMPdf$NF, ncol= obMPdf$NF)
    
    LM = I - 0.5*obMPdf$deltat * obMPdf$sigmaF^2 * D2 - obMPdf$deltat * obMPdf$alfaF * obMPdf$FF* D1
    return(base::solve(LM))
    
}
    #Zapolniaem matritcy` na setke F x F
#     for (i in 1:obMPdf$NF)
#     {
# #         k = 1
# #         if (i <= obMPdf$NF/ 2) 
# #             k = i
# #         else 
# #             k = i - 1
# #         D1[i, k] = -1 / obMPdf$deltaF
# #         D1[i, k + 1] = 1 /obMPdf$deltaF
# #         if (i == 1)
# #         {
# #             D2[i, i + 1] = 2 / obMPdf$deltaF^2
# #         }
# #         else if (i == obMPdf$NF)
# #         {
# #             D2[i, i - 1] = 2 / obMPdf$deltaF^2
# #         }
# #         else
# #         {
# #             D2[i, i - 1] = 1 / obMPdf$deltaF^2
# #             D2[i, i + 1] = 1 / obMPdf$deltaF^2
# #         }
# #         D2[i, i] = -2 / obMPdf$deltaF^2
#         
#         #Vy`chisliaem znacheniia matrichnoi` chasti vy`razheniia operatora L
#         #cft[1] - znachenie sigmaF iz uravneniia Ornshtei`na-Ulenbeka dlia Ft,
#         #cft[0] - znachenie alfaF
#         for (j in 1:obMPdf$NF)
#         {
#             LM[i, j] = I[i, j] - 0.5*obMPdf$deltat * obMPdf$sigmaF^2 * D2[i, j] - obMPdf$deltat * obMPdf$alfaF *obMPdf$FF[i]  * D1[i, j]
#         }
#     }
#     #Invertiruem matritcu, ispol`zuia storonniuiu biblioteku alglib
