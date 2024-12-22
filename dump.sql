--
-- PostgreSQL database dump
--

-- Dumped from database version 16.3 (Debian 16.3-1+b1)
-- Dumped by pg_dump version 16.3 (Debian 16.3-1+b1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: public; Type: SCHEMA; Schema: -; Owner: cshamaloow
--

CREATE SCHEMA public;


ALTER SCHEMA public OWNER TO cshamaloow;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: carte; Type: TABLE; Schema: public; Owner: cshamaloow
--

CREATE TABLE public.carte (
    nom character varying(100) NOT NULL,
    atk_ integer DEFAULT 0,
    def_ integer DEFAULT 0,
    prix numeric(10,2) DEFAULT 0.00,
    CONSTRAINT carte_atk__check CHECK ((atk_ >= 0)),
    CONSTRAINT carte_def__check CHECK ((def_ >= 0)),
    CONSTRAINT carte_prix_check CHECK ((prix >= (0)::numeric))
);


ALTER TABLE public.carte OWNER TO cshamaloow;

--
-- Name: collectionne; Type: TABLE; Schema: public; Owner: cshamaloow
--

CREATE TABLE public.collectionne (
    nom character varying(50) NOT NULL,
    id_joueur integer NOT NULL
);


ALTER TABLE public.collectionne OWNER TO cshamaloow;

--
-- Name: confronte; Type: TABLE; Schema: public; Owner: cshamaloow
--

CREATE TABLE public.confronte (
    id_deck_vainqueur integer NOT NULL,
    id_deck_perdant integer NOT NULL,
    date_ timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.confronte OWNER TO cshamaloow;

--
-- Name: contient; Type: TABLE; Schema: public; Owner: cshamaloow
--

CREATE TABLE public.contient (
    nom character varying(50) NOT NULL,
    id_deck integer NOT NULL
);


ALTER TABLE public.contient OWNER TO cshamaloow;

--
-- Name: cout; Type: TABLE; Schema: public; Owner: cshamaloow
--

CREATE TABLE public.cout (
    couleur character varying(50) NOT NULL,
    nom character varying(50) NOT NULL,
    nombre integer
);


ALTER TABLE public.cout OWNER TO cshamaloow;

--
-- Name: cout_concat; Type: VIEW; Schema: public; Owner: cshamaloow
--

CREATE VIEW public.cout_concat AS
 SELECT nom,
    string_agg(repeat(upper(SUBSTRING(couleur FROM 1 FOR 1)), nombre), ''::text ORDER BY couleur) AS coc
   FROM public.cout c2
  GROUP BY nom;


ALTER VIEW public.cout_concat OWNER TO cshamaloow;

--
-- Name: deck; Type: TABLE; Schema: public; Owner: cshamaloow
--

CREATE TABLE public.deck (
    id_deck integer NOT NULL,
    "nom_général" character varying(100) NOT NULL,
    id_joueur integer NOT NULL,
    nom character varying(50),
    description text
);


ALTER TABLE public.deck OWNER TO cshamaloow;

--
-- Name: deck_id_deck_seq; Type: SEQUENCE; Schema: public; Owner: cshamaloow
--

CREATE SEQUENCE public.deck_id_deck_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.deck_id_deck_seq OWNER TO cshamaloow;

--
-- Name: deck_id_deck_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: cshamaloow
--

ALTER SEQUENCE public.deck_id_deck_seq OWNED BY public.deck.id_deck;


--
-- Name: deck_valide; Type: VIEW; Schema: public; Owner: cshamaloow
--

CREATE VIEW public.deck_valide AS
 SELECT id_deck,
    count(*) AS count
   FROM ( SELECT DISTINCT con1.nom,
            de2.id_deck
           FROM (public.contient con1
             JOIN public.deck de2 ON ((de2.id_deck = con1.id_deck)))
          WHERE (NOT (EXISTS ( SELECT cout.couleur
                   FROM public.cout
                  WHERE ((cout.nom)::text = (con1.nom)::text)
                EXCEPT
                 SELECT co1.couleur
                   FROM public.cout co1
                  WHERE ((co1.nom)::text = (de2."nom_général")::text))))) requete
  GROUP BY id_deck
 HAVING ((count(*) = 16) AND (count(*) = ( SELECT count(*) AS count
           FROM public.contient
          WHERE (contient.id_deck = requete.id_deck))));


ALTER VIEW public.deck_valide OWNER TO cshamaloow;

--
-- Name: deck_valide_collection_joueur; Type: VIEW; Schema: public; Owner: cshamaloow
--

CREATE VIEW public.deck_valide_collection_joueur AS
 SELECT id_deck,
    count
   FROM public.deck_valide d1
  WHERE (NOT (EXISTS ( SELECT 1
           FROM public.contient c
          WHERE ((c.id_deck = d1.id_deck) AND (NOT (EXISTS ( SELECT 1
                   FROM (public.collectionne col
                     JOIN public.deck ON ((deck.id_joueur = col.id_joueur)))
                  WHERE ((deck.id_deck = d1.id_deck) AND ((col.nom)::text = (c.nom)::text)))))))));


ALTER VIEW public.deck_valide_collection_joueur OWNER TO cshamaloow;

--
-- Name: est_type; Type: TABLE; Schema: public; Owner: cshamaloow
--

CREATE TABLE public.est_type (
    nom character varying(50) NOT NULL,
    nom_type character varying(50) NOT NULL
);


ALTER TABLE public.est_type OWNER TO cshamaloow;

--
-- Name: joueur; Type: TABLE; Schema: public; Owner: cshamaloow
--

CREATE TABLE public.joueur (
    id_joueur integer NOT NULL,
    pseudo character varying(50) NOT NULL,
    email character varying(100) NOT NULL,
    mdp character varying(255) NOT NULL,
    uav integer DEFAULT 0,
    CONSTRAINT joueur_uav_check CHECK ((uav >= 0))
);


ALTER TABLE public.joueur OWNER TO cshamaloow;

--
-- Name: joueur_id_joueur_seq; Type: SEQUENCE; Schema: public; Owner: cshamaloow
--

CREATE SEQUENCE public.joueur_id_joueur_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.joueur_id_joueur_seq OWNER TO cshamaloow;

--
-- Name: joueur_id_joueur_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: cshamaloow
--

ALTER SEQUENCE public.joueur_id_joueur_seq OWNED BY public.joueur.id_joueur;


--
-- Name: mana; Type: TABLE; Schema: public; Owner: cshamaloow
--

CREATE TABLE public.mana (
    couleur character varying(50)
);


ALTER TABLE public.mana OWNER TO cshamaloow;

--
-- Name: taux_victoire_carte; Type: VIEW; Schema: public; Owner: cshamaloow
--

CREATE VIEW public.taux_victoire_carte AS
 SELECT c1.nom,
    round(((((count(*))::numeric * 1.0) / (( SELECT count(*) AS count
           FROM (public.contient c2
             JOIN public.confronte con2 ON (((c2.id_deck = con2.id_deck_vainqueur) OR (c2.id_deck = con2.id_deck_perdant))))
          WHERE ((c2.nom)::text = (c1.nom)::text)))::numeric) * (100)::numeric), 2) AS taux_victoire
   FROM (public.contient c1
     JOIN public.confronte con1 ON ((c1.id_deck = con1.id_deck_vainqueur)))
  GROUP BY c1.nom;


ALTER VIEW public.taux_victoire_carte OWNER TO cshamaloow;

--
-- Name: meilleur_general_par_comb_mana; Type: VIEW; Schema: public; Owner: cshamaloow
--

CREATE VIEW public.meilleur_general_par_comb_mana AS
 SELECT DISTINCT co1.nom,
    string_agg((co1.couleur)::text, '|'::text) AS combinaison_mana,
    ta1.taux_victoire
   FROM ((public.deck de1(id_deck, "nom_général", id_joueur, nom_1, description)
     JOIN public.cout co1 ON (((de1."nom_général")::text = (co1.nom)::text)))
     JOIN public.taux_victoire_carte ta1 USING (nom))
  WHERE (ta1.taux_victoire = ( SELECT max(unnamed_subquery.taux_victoire) AS max
           FROM ( SELECT ta2.taux_victoire
                   FROM (public.deck de2
                     JOIN public.taux_victoire_carte ta2 ON (((de2."nom_général")::text = (ta2.nom)::text)))
                  WHERE ((NOT (EXISTS ( SELECT co2.couleur
                           FROM public.cout co2
                          WHERE ((co2.nom)::text = (de1."nom_général")::text)
                        EXCEPT
                         SELECT co3.couleur
                           FROM public.cout co3
                          WHERE ((co3.nom)::text = (de2."nom_général")::text)))) AND (( SELECT count(*) AS count
                           FROM public.cout
                          WHERE ((cout.nom)::text = (de1."nom_général")::text)) = ( SELECT count(*) AS count
                           FROM public.cout
                          WHERE ((de2."nom_général")::text = (cout.nom)::text))))) unnamed_subquery))
  GROUP BY co1.nom, ta1.taux_victoire;


ALTER VIEW public.meilleur_general_par_comb_mana OWNER TO cshamaloow;

--
-- Name: nbre_victoire_par_cartes; Type: VIEW; Schema: public; Owner: cshamaloow
--

CREATE VIEW public.nbre_victoire_par_cartes AS
 SELECT c.nom AS carte,
    count(*) AS nombre_victoires
   FROM ((public.contient ct
     JOIN public.confronte con ON ((ct.id_deck = con.id_deck_vainqueur)))
     JOIN public.carte c ON (((ct.nom)::text = (c.nom)::text)))
  GROUP BY c.nom
  ORDER BY (count(*)) DESC;


ALTER VIEW public.nbre_victoire_par_cartes OWNER TO cshamaloow;

--
-- Name: nbre_victore_avk_chq_carte; Type: VIEW; Schema: public; Owner: cshamaloow
--

CREATE VIEW public.nbre_victore_avk_chq_carte AS
 SELECT c1.nom AS carte_principale,
    c2.nom AS carte_associee,
    count(*) AS nombre_victoires
   FROM ((((public.contient ct1
     JOIN public.contient ct2 ON (((ct1.id_deck = ct2.id_deck) AND ((ct1.nom)::text <> (ct2.nom)::text))))
     JOIN public.confronte con ON ((ct1.id_deck = con.id_deck_vainqueur)))
     JOIN public.carte c1 ON (((ct1.nom)::text = (c1.nom)::text)))
     JOIN public.carte c2 ON (((ct2.nom)::text = (c2.nom)::text)))
  GROUP BY c1.nom, c2.nom
  ORDER BY c1.nom, (count(*)) DESC;


ALTER VIEW public.nbre_victore_avk_chq_carte OWNER TO cshamaloow;

--
-- Name: pourcentage_carte_deck_legale; Type: VIEW; Schema: public; Owner: cshamaloow
--

CREATE VIEW public.pourcentage_carte_deck_legale AS
 SELECT contient.nom,
    round(((((count(*))::numeric * 1.0) / (( SELECT count(*) AS count
           FROM public.deck_valide deck_valide_1))::numeric) * (100)::numeric), 2) AS pourcentage_utilisation
   FROM (public.contient
     JOIN public.deck_valide USING (id_deck))
  GROUP BY contient.nom
  ORDER BY (round(((((count(*))::numeric * 1.0) / (( SELECT count(*) AS count
           FROM public.deck_valide deck_valide_1))::numeric) * (100)::numeric), 2)) DESC;


ALTER VIEW public.pourcentage_carte_deck_legale OWNER TO cshamaloow;

--
-- Name: stats_cartes; Type: VIEW; Schema: public; Owner: cshamaloow
--

CREATE VIEW public.stats_cartes AS
 SELECT nom,
    carte.atk_,
    carte.def_,
    string_agg((est_type.nom_type)::text, ','::text ORDER BY nom) AS types,
    cout_concat.coc
   FROM ((public.carte
     JOIN public.est_type USING (nom))
     JOIN public.cout_concat USING (nom))
  GROUP BY nom, carte.atk_, carte.def_, cout_concat.coc;


ALTER VIEW public.stats_cartes OWNER TO cshamaloow;

--
-- Name: suggérer; Type: TABLE; Schema: public; Owner: cshamaloow
--

CREATE TABLE public."suggérer" (
    id_joueur integer NOT NULL,
    id_deck integer NOT NULL,
    "carte_retirée" character varying(50) NOT NULL,
    "carte_ajoutée" character varying(50) NOT NULL,
    id_proprio integer
);


ALTER TABLE public."suggérer" OWNER TO cshamaloow;

--
-- Name: synergie_général; Type: VIEW; Schema: public; Owner: cshamaloow
--

CREATE VIEW public."synergie_général" AS
 SELECT n1.carte_principale AS carte,
    n1.carte_associee,
    round(((((n1.nombre_victoires)::numeric * 1.0) / (n2.nombre_victoires)::numeric) * (100)::numeric), 2) AS taux_victoire,
    round((((((n2.nombre_victoires - n1.nombre_victoires))::numeric * 1.0) / (n2.nombre_victoires)::numeric) * (100)::numeric), 2) AS taux_victoire_sans_carte,
    round(abs((((((n1.nombre_victoires)::numeric * 1.0) / (n2.nombre_victoires)::numeric) * (100)::numeric) - (((((n2.nombre_victoires - n1.nombre_victoires))::numeric * 1.0) / (n2.nombre_victoires)::numeric) * (100)::numeric))), 2) AS difference_taux_victoire
   FROM (public.nbre_victore_avk_chq_carte n1
     JOIN public.nbre_victoire_par_cartes n2 ON (((n1.carte_principale)::text = (n2.carte)::text)))
  WHERE ((n2.carte)::text IN ( SELECT deck."nom_général"
           FROM public.deck))
  ORDER BY n1.carte_principale, (round(abs((((((n1.nombre_victoires)::numeric * 1.0) / (n2.nombre_victoires)::numeric) * (100)::numeric) - (((((n2.nombre_victoires - n1.nombre_victoires))::numeric * 1.0) / (n2.nombre_victoires)::numeric) * (100)::numeric))), 2)) DESC;


ALTER VIEW public."synergie_général" OWNER TO cshamaloow;

--
-- Name: taux_defaite_solo; Type: VIEW; Schema: public; Owner: cshamaloow
--

CREATE VIEW public.taux_defaite_solo AS
 SELECT id_deck_vainqueur AS id_deck,
    round(((((( SELECT count(*) AS count
           FROM public.confronte
          WHERE (confronte.id_deck_perdant = c1.id_deck_vainqueur)))::numeric * 1.0) / (( SELECT count(*) AS count
           FROM public.confronte
          WHERE ((confronte.id_deck_vainqueur = c1.id_deck_vainqueur) OR (confronte.id_deck_perdant = c1.id_deck_vainqueur))))::numeric) * (100)::numeric), 2) AS taux_defaite
   FROM public.confronte c1
  GROUP BY id_deck_vainqueur;


ALTER VIEW public.taux_defaite_solo OWNER TO cshamaloow;

--
-- Name: taux_victoire_deck; Type: VIEW; Schema: public; Owner: cshamaloow
--

CREATE VIEW public.taux_victoire_deck AS
 SELECT id_deck_vainqueur,
    id_deck_perdant,
    count(*) AS victoire,
    ( SELECT count(*) AS count
           FROM public.confronte conf1
          WHERE (((conf1.id_deck_vainqueur = confronte.id_deck_vainqueur) AND (conf1.id_deck_perdant = confronte.id_deck_perdant)) OR ((conf1.id_deck_vainqueur = confronte.id_deck_perdant) AND (conf1.id_deck_perdant = confronte.id_deck_vainqueur)))) AS nbre_combat,
    round(((((count(*))::numeric * 1.00) / (( SELECT count(*) AS count
           FROM public.confronte conf1
          WHERE (((conf1.id_deck_vainqueur = confronte.id_deck_vainqueur) AND (conf1.id_deck_perdant = confronte.id_deck_perdant)) OR ((conf1.id_deck_vainqueur = confronte.id_deck_perdant) AND (conf1.id_deck_perdant = confronte.id_deck_vainqueur)))))::numeric) * (100)::numeric), 2) AS taux_victoire
   FROM public.confronte
  GROUP BY id_deck_vainqueur, id_deck_perdant
  ORDER BY id_deck_vainqueur;


ALTER VIEW public.taux_victoire_deck OWNER TO cshamaloow;

--
-- Name: taux_victoire_deck_solo; Type: VIEW; Schema: public; Owner: cshamaloow
--

CREATE VIEW public.taux_victoire_deck_solo AS
 SELECT id_deck_vainqueur AS id_deck,
    round(((((( SELECT count(*) AS count
           FROM public.confronte
          WHERE (confronte.id_deck_vainqueur = c1.id_deck_vainqueur)))::numeric * 1.0) / (( SELECT count(*) AS count
           FROM public.confronte
          WHERE ((confronte.id_deck_vainqueur = c1.id_deck_vainqueur) OR (confronte.id_deck_perdant = c1.id_deck_vainqueur))))::numeric) * (100)::numeric), 2) AS taux_victoire
   FROM public.confronte c1
  GROUP BY id_deck_vainqueur;


ALTER VIEW public.taux_victoire_deck_solo OWNER TO cshamaloow;

--
-- Name: type; Type: TABLE; Schema: public; Owner: cshamaloow
--

CREATE TABLE public.type (
    nom_type character varying(50) NOT NULL
);


ALTER TABLE public.type OWNER TO cshamaloow;

--
-- Name: deck id_deck; Type: DEFAULT; Schema: public; Owner: cshamaloow
--

ALTER TABLE ONLY public.deck ALTER COLUMN id_deck SET DEFAULT nextval('public.deck_id_deck_seq'::regclass);


--
-- Name: joueur id_joueur; Type: DEFAULT; Schema: public; Owner: cshamaloow
--

ALTER TABLE ONLY public.joueur ALTER COLUMN id_joueur SET DEFAULT nextval('public.joueur_id_joueur_seq'::regclass);


--
-- Data for Name: carte; Type: TABLE DATA; Schema: public; Owner: cshamaloow
--

COPY public.carte (nom, atk_, def_, prix) FROM stdin;
Legolas	0	300000	100.00
Salogel	300000	0	150.00
Dragon Gentil	100	60	50.00
Chevalier Perdu	60	40	30.00
Roi des Chiens	80	60	80.00
Dragon de Feu	250	200	120.00
Chevalier Argent	180	150	90.00
Mage Sombre	150	100	70.00
Archère Elfique	100	80	50.00
Golem de Pierre	300	350	200.00
Roi des Ombres	200	250	150.00
Monstre Aquatique	220	200	110.00
Loup Sauvage	120	100	60.00
Chevalier Enflammé	190	130	85.00
Sorcière des Vents	140	90	65.00
Golem de Glace	270	320	180.00
Dragon Électrique	230	210	130.00
Chevalier Fantôme	160	170	75.00
Archer Noir	110	70	40.00
Roi des Dragons	280	250	200.00
Légionnaire Céleste	220	180	95.00
Spectre de la Nuit	250	230	140.00
Basilic Doré	180	160	110.00
Garde du Royaume	210	190	130.00
Mage des Ombres	160	140	90.00
Sphinx Mystique	240	210	160.00
Troll des Cavernes	270	250	175.00
Elfe des Bois	130	110	65.00
Sorcier du Vent	150	120	85.00
Berserker Sauvage	220	200	100.00
Titan de Fer	300	320	200.00
Anubis le Démon	250	270	180.00
Fée Magique	100	50	30.00
Démon Infernal	260	240	175.00
Nécromancien	180	140	90.00
Valkyrie	230	220	140.00
Dragon Ancien	300	280	210.00
Sable de Tempête	150	130	75.00
Serpent Géant	200	180	100.00
Golem Magique	220	230	150.00
Shaman Elfe	120	100	60.00
Homme-Rat	80	70	40.00
Garde de Fer	230	210	130.00
Faucheuse Nocturne	250	240	160.00
Faucon Royal	150	130	80.00
Fureur du Dragon	240	220	170.00
Druidessa	180	160	100.00
Ombre de Guerre	190	170	110.00
Licorne Magique	160	140	90.00
Maître des Éléments	200	180	120.00
Garde Souterraine	260	250	180.00
Roi des Cieux	280	260	190.00
Sphinx Doré	210	190	130.00
Spectre Energie	250	230	140.00
Golem de Métal	280	270	200.00
Vampire Immortel	240	220	170.00
Soldat Élite	210	180	120.00
Titan du Vent	250	240	160.00
Berserker Infernal	260	240	180.00
Démon Céleste	230	210	140.00
Fée or	170	150	100.00
Golem Céleste	220	200	130.00
Élémentaire de Feu	240	220	160.00
Mage de Lumière	180	160	90.00
Légionnaire de Fer	230	200	120.00
Basilic des Cavernes	200	180	100.00
Dragon Mystique	300	280	210.00
Kitsune Enragée	250	230	160.00
Sorcière Obscurité	220	200	130.00
Golem de Magie	250	220	160.00
Tigre Sauvage	180	160	110.00
Ninja Fantôme	150	130	80.00
Guerrier Céleste	220	210	140.00
Dragon Sombre	300	280	200.00
Sphinx Argent	230	210	150.00
Chevalier Spectral	210	190	120.00
Cobra Empoisonné	160	140	80.00
Loup Fantôme	190	170	120.00
Druide Sauvage	180	160	100.00
Sirène Enchanteresse	210	190	140.00
Chevalier Solaire	230	210	130.00
Golem de Flamme	250	240	170.00
Sorceleur Vert	3	2	5.00
Guerrier de la Forêt	4	5	7.50
Chaman Sauvage	2	6	4.20
\.


--
-- Data for Name: collectionne; Type: TABLE DATA; Schema: public; Owner: cshamaloow
--

COPY public.collectionne (nom, id_joueur) FROM stdin;
Legolas	1
Chevalier Perdu	1
Roi des Chiens	1
Dragon de Feu	1
Chevalier Argent	1
Mage Sombre	1
Sphinx Doré	1
Archère Elfique	1
Golem de Pierre	1
Roi des Ombres	1
Monstre Aquatique	1
Loup Sauvage	1
Chevalier Enflammé	1
Sorcière des Vents	1
Golem de Glace	1
Dragon Électrique	1
Archer Noir	1
Basilic Doré	1
Berserker Infernal	1
Chaman Sauvage	1
Chevalier Fantôme	1
Chevalier Solaire	1
Dragon Gentil	1
Démon Infernal	1
Elfe des Bois	1
Fureur du Dragon	1
Garde du Royaume	1
Golem Céleste	1
Golem Magique	1
Guerrier de la Forêt	1
Légionnaire Céleste	1
Maître des Éléments	1
Roi des Dragons	1
Sable de Tempête	1
Salogel	1
Soldat Élite	1
Sorceleur Vert	1
Spectre de la Nuit	1
Sphinx Argent	1
Sphinx Mystique	1
Tigre Sauvage	1
Titan de Fer	1
Troll des Cavernes	1
Valkyrie	1
Archère Elfique	2
Dragon Électrique	5
Chevalier Fantôme	4
Loup Sauvage	3
Sable de Tempête	5
Chevalier Argent	5
Roi des Ombres	5
Monstre Aquatique	2
Chevalier Enflammé	5
Loup Sauvage	4
Roi des Chiens	5
Dragon de Feu	4
Golem de Glace	2
Chevalier Enflammé	3
Légionnaire Céleste	3
Sorcière des Vents	3
Dragon Électrique	3
Chevalier Fantôme	2
Golem de Pierre	5
Chevalier Perdu	4
Chevalier Enflammé	2
Golem de Glace	5
Sorcière des Vents	4
Dragon Gentil	3
Loup Sauvage	2
Monstre Aquatique	4
Légionnaire Céleste	5
Chevalier Solaire	4
Chevalier Fantôme	5
Chevalier Fantôme	3
Archer Noir	4
Golem de Glace	3
Monstre Aquatique	3
Sorcière des Vents	2
Golem de Pierre	2
Dragon de Feu	2
Légionnaire Céleste	2
Loup Sauvage	5
Monstre Aquatique	5
Dragon Électrique	4
Archer Noir	2
Spectre de la Nuit	3
Roi des Chiens	4
Dragon de Feu	5
Chevalier Argent	3
Roi des Dragons	3
Roi des Dragons	2
Salogel	2
Mage Sombre	5
Mage Sombre	4
Chevalier Enflammé	4
Golem de Pierre	4
Archère Elfique	5
Golem de Pierre	3
Roi des Ombres	4
Mage Sombre	2
Roi des Ombres	2
Dragon de Feu	3
Archère Elfique	3
Sorcière des Vents	5
Dragon Électrique	2
Golem de Glace	4
Chevalier Argent	4
Roi des Ombres	3
Guerrier Céleste	3
Kitsune Enragée	3
Licorne Magique	3
Golem Céleste	3
Basilic des Cavernes	3
Basilic Doré	3
Shaman Elfe	3
Tigre Sauvage	3
Sphinx Mystique	3
Salogel	3
\.


--
-- Data for Name: confronte; Type: TABLE DATA; Schema: public; Owner: cshamaloow
--

COPY public.confronte (id_deck_vainqueur, id_deck_perdant, date_) FROM stdin;
100	101	2024-11-17 17:36:23.735869
102	103	2024-11-17 17:36:23.7401
104	105	2024-11-17 17:36:23.742367
101	102	2024-11-17 17:36:23.744595
105	100	2024-11-17 17:36:23.746836
103	104	2024-11-17 17:36:23.749042
100	101	2024-11-17 17:37:00.029465
102	103	2024-11-17 17:37:00.032488
104	105	2024-11-17 17:37:00.034714
101	102	2024-11-17 17:37:00.036951
105	100	2024-11-17 17:37:00.039206
103	104	2024-11-17 17:37:00.041868
100	103	2024-11-17 17:37:00.044493
102	104	2024-11-17 17:37:00.046955
105	101	2024-11-17 17:37:00.049131
104	100	2024-11-17 17:37:00.051373
103	105	2024-11-17 17:37:00.053501
101	102	2024-11-17 17:37:00.055681
101	104	2024-11-17 17:37:00.057916
103	100	2024-11-17 17:37:00.060559
105	102	2024-11-17 17:37:00.063105
106	107	2024-11-17 21:19:27.199961
101	100	2024-11-17 23:25:42.550275
\.


--
-- Data for Name: contient; Type: TABLE DATA; Schema: public; Owner: cshamaloow
--

COPY public.contient (nom, id_deck) FROM stdin;
Legolas	100
Chevalier Perdu	100
Roi des Chiens	100
Dragon de Feu	100
Chevalier Argent	100
Mage Sombre	100
Sphinx Doré	100
Archère Elfique	100
Golem de Pierre	100
Roi des Ombres	100
Monstre Aquatique	100
Loup Sauvage	100
Chevalier Enflammé	100
Sorcière des Vents	100
Golem de Glace	100
Dragon Électrique	100
Salogel	101
Mage Sombre	101
Dragon de Feu	101
Archère Elfique	101
Golem de Pierre	101
Roi des Ombres	101
Monstre Aquatique	101
Loup Sauvage	101
Chevalier Enflammé	101
Sorcière des Vents	101
Golem de Glace	101
Dragon Électrique	101
Chevalier Fantôme	101
Archer Noir	101
Roi des Dragons	101
Légionnaire Céleste	101
Dragon Gentil	102
Dragon de Feu	102
Chevalier Argent	102
Archère Elfique	102
Golem de Pierre	102
Roi des Ombres	102
Loup Sauvage	102
Chevalier Enflammé	102
Dragon Électrique	102
Chevalier Fantôme	102
Spectre de la Nuit	102
Roi des Dragons	102
Chevalier Perdu	103
Dragon de Feu	103
Chevalier Argent	103
Mage Sombre	103
Roi des Chiens	103
Golem de Pierre	103
Roi des Ombres	103
Monstre Aquatique	103
Loup Sauvage	103
Chevalier Enflammé	103
Sorcière des Vents	103
Golem de Glace	103
Dragon Électrique	103
Chevalier Fantôme	103
Chevalier Solaire	103
Archer Noir	103
Roi des Chiens	104
Dragon de Feu	104
Chevalier Argent	104
Mage Sombre	104
Archère Elfique	104
Golem de Pierre	104
Roi des Ombres	104
Monstre Aquatique	104
Loup Sauvage	104
Chevalier Enflammé	104
Sorcière des Vents	104
Golem de Glace	104
Dragon Électrique	104
Légionnaire Céleste	104
Sable de Tempête	104
Chevalier Fantôme	104
Loup Sauvage	107
Legolas	107
Salogel	107
Legolas	105
Chevalier Perdu	105
Roi des Chiens	105
Dragon de Feu	105
Chevalier Argent	105
Mage Sombre	105
Chevalier Enflammé	105
Sorcière des Vents	105
Golem de Glace	105
Dragon Électrique	105
Archer Noir	105
Roi des Dragons	105
Spectre de la Nuit	105
Basilic Doré	105
Sphinx Mystique	105
Titan de Fer	105
Legolas	106
Dragon Gentil	106
Chevalier Argent	106
Archère Elfique	106
Golem de Glace	106
Chevalier Fantôme	106
Roi des Dragons	106
Légionnaire Céleste	106
Garde du Royaume	106
Troll des Cavernes	106
Elfe des Bois	106
Titan de Fer	106
Démon Infernal	106
Valkyrie	106
Sable de Tempête	106
Golem Magique	106
Archère Elfique	108
Loup Sauvage	108
Elfe des Bois	108
Golem Magique	108
Fureur du Dragon	108
Maître des Éléments	108
Sphinx Doré	108
Soldat Élite	108
Berserker Infernal	108
Golem Céleste	108
Tigre Sauvage	108
Sphinx Argent	108
Chevalier Solaire	108
Sorceleur Vert	108
Guerrier de la Forêt	108
Chaman Sauvage	108
Salogel	111
Dragon Sombre	111
Faucon Royal	111
Fée Magique	111
Fée or	111
Golem de Pierre	111
Kitsune Enragée	111
Loup Fantôme	111
Légionnaire de Fer	111
Serpent Géant	111
Vampire Immortel	111
Roi des Chiens	111
Legolas	111
Berserker Sauvage	111
Archère Elfique	111
Mage Sombre	111
Salogel	112
Dragon Sombre	112
Faucon Royal	112
Fée Magique	112
Fée or	112
Golem de Pierre	112
Kitsune Enragée	112
Loup Fantôme	112
Légionnaire de Fer	112
Serpent Géant	112
Vampire Immortel	112
Roi des Chiens	112
Legolas	112
Berserker Sauvage	112
Archère Elfique	112
Mage Sombre	112
Monstre Aquatique	112
Spectre Energie	111
Chevalier Perdu	114
Dragon de Feu	114
Chevalier Argent	114
Mage Sombre	114
Roi des Chiens	114
Golem de Pierre	114
Roi des Ombres	114
Monstre Aquatique	114
Loup Sauvage	114
Chevalier Enflammé	114
Sorcière des Vents	114
Golem de Glace	114
Dragon Électrique	114
Chevalier Fantôme	114
Chevalier Solaire	114
Archer Noir	114
Roi des Chiens	117
Dragon de Feu	117
Chevalier Argent	117
Mage Sombre	117
Archère Elfique	117
Golem de Pierre	117
Roi des Ombres	117
Monstre Aquatique	117
Loup Sauvage	117
Chevalier Enflammé	117
Sorcière des Vents	117
Golem de Glace	117
Dragon Électrique	117
Légionnaire Céleste	117
Sable de Tempête	117
Chevalier Fantôme	117
Berserker Infernal	102
Spectre Energie	102
Elfe des Bois	102
Roi des Chiens	118
Dragon de Feu	118
Chevalier Argent	118
Mage Sombre	118
Archère Elfique	118
Golem de Pierre	118
Roi des Ombres	118
Monstre Aquatique	118
Loup Sauvage	118
Chevalier Enflammé	118
Sorcière des Vents	118
Golem de Glace	118
Dragon Électrique	118
Légionnaire Céleste	118
Sable de Tempête	118
Chevalier Fantôme	118
Chevalier Perdu	119
Dragon de Feu	119
Chevalier Argent	119
Mage Sombre	119
Roi des Chiens	119
Golem de Pierre	119
Roi des Ombres	119
Monstre Aquatique	119
Loup Sauvage	119
Chevalier Enflammé	119
Sorcière des Vents	119
Golem de Glace	119
Dragon Électrique	119
Chevalier Fantôme	119
Chevalier Solaire	119
Archer Noir	119
\.


--
-- Data for Name: cout; Type: TABLE DATA; Schema: public; Owner: cshamaloow
--

COPY public.cout (couleur, nom, nombre) FROM stdin;
jaune	Legolas	1
vert	Legolas	2
rouge	Salogel	3
vert	Dragon Gentil	1
rouge	Dragon Gentil	1
jaune	Chevalier Perdu	1
rouge	Chevalier Perdu	1
jaune	Roi des Chiens	1
rouge	Roi des Chiens	1
jaune	Dragon de Feu	1
rouge	Dragon de Feu	2
jaune	Chevalier Argent	1
vert	Chevalier Argent	1
jaune	Mage Sombre	1
bleu	Mage Sombre	1
vert	Archère Elfique	1
rouge	Golem de Pierre	2
rouge	Roi des Ombres	1
noir	Roi des Ombres	1
bleu	Monstre Aquatique	1
vert	Loup Sauvage	1
jaune	Chevalier Enflammé	1
rouge	Chevalier Enflammé	1
jaune	Sorcière des Vents	1
bleu	Sorcière des Vents	1
jaune	Golem de Glace	2
vert	Golem de Glace	1
rouge	Dragon Électrique	1
jaune	Dragon Électrique	1
vert	Chevalier Fantôme	1
noir	Chevalier Fantôme	1
jaune	Archer Noir	1
vert	Roi des Dragons	2
jaune	Roi des Dragons	1
bleu	Légionnaire Céleste	1
vert	Légionnaire Céleste	1
jaune	Spectre de la Nuit	1
noir	Spectre de la Nuit	1
rouge	Basilic Doré	1
jaune	Basilic Doré	1
vert	Garde du Royaume	1
rouge	Garde du Royaume	1
bleu	Mage des Ombres	1
noir	Mage des Ombres	1
jaune	Sphinx Mystique	1
bleu	Sphinx Mystique	1
vert	Troll des Cavernes	2
rouge	Troll des Cavernes	1
vert	Elfe des Bois	1
bleu	Sorcier du Vent	1
rouge	Berserker Sauvage	1
jaune	Titan de Fer	2
vert	Titan de Fer	1
noir	Anubis le Démon	1
jaune	Anubis le Démon	1
rouge	Fée Magique	1
vert	Démon Infernal	1
noir	Démon Infernal	1
jaune	Nécromancien	1
noir	Nécromancien	1
vert	Valkyrie	1
jaune	Valkyrie	1
rouge	Dragon Ancien	2
jaune	Dragon Ancien	1
bleu	Sable de Tempête	1
vert	Sable de Tempête	1
rouge	Serpent Géant	1
vert	Golem Magique	1
bleu	Shaman Elfe	1
jaune	Homme-Rat	1
noir	Garde de Fer	1
vert	Faucheuse Nocturne	1
jaune	Faucheuse Nocturne	1
rouge	Faucon Royal	1
vert	Fureur du Dragon	1
noir	Druidessa	1
jaune	Druidessa	1
rouge	Ombre de Guerre	1
vert	Ombre de Guerre	1
jaune	Licorne Magique	1
vert	Maître des Éléments	1
jaune	Garde Souterraine	2
noir	Roi des Cieux	1
vert	Sphinx Doré	1
bleu	Spectre Energie	1
noir	Golem de Métal	2
rouge	Vampire Immortel	1
vert	Soldat Élite	1
jaune	Titan du Vent	1
vert	Berserker Infernal	1
bleu	Démon Céleste	1
rouge	Fée or	1
vert	Golem Céleste	1
jaune	Élémentaire de Feu	1
bleu	Mage de Lumière	1
rouge	Légionnaire de Fer	1
noir	Basilic des Cavernes	1
jaune	Dragon Mystique	1
rouge	Kitsune Enragée	1
bleu	Sorcière Obscurité	1
jaune	Golem de Magie	1
vert	Tigre Sauvage	1
noir	Ninja Fantôme	1
jaune	Guerrier Céleste	1
rouge	Dragon Sombre	1
vert	Sphinx Argent	1
noir	Chevalier Spectral	1
jaune	Cobra Empoisonné	1
rouge	Loup Fantôme	1
noir	Druide Sauvage	1
jaune	Sirène Enchanteresse	1
vert	Chevalier Solaire	1
rouge	Golem de Flamme	1
vert	Sorceleur Vert	1
vert	Guerrier de la Forêt	1
vert	Chaman Sauvage	1
\.


--
-- Data for Name: deck; Type: TABLE DATA; Schema: public; Owner: cshamaloow
--

COPY public.deck (id_deck, "nom_général", id_joueur, nom, description) FROM stdin;
100	Legolas	1	Par defaut	Lorem ipsum dolor sit amet, consectetur adipiscing elit. Aenean sit amet dignissim purus, et consectetur augue. Proin varius lacus ac justo vulputate condimentum. Sed dapibus porttitor mi. Integer felis lacus, ornare vel consequat eu, imperdiet id nunc. In ullamcorper nisl a egestas gravida. Curabitur orci tellus, suscipit a convallis id, Integer convallis, velit ac venenatis fringilla, turpis dui varius dolor, eu viverra tellus lacus vitae mi. Sed leo purus, fermentum ut turpis eu, lacinia lacinia lectus. Etiam iaculis mauris eget neque semper commodo. In tempor ornare tortor.
109	Legolas	3	dz	Lorem ipsum dolor sit amet, consectetur adipiscing elit. Aenean sit amet dignissim purus, et consectetur augue. Proin varius lacus ac justo vulputate condimentum. Sed dapibus porttitor mi. Integer felis lacus, ornare vel consequat eu, imperdiet id nunc. In ullamcorper nisl a egestas gravida. Curabitur orci tellus, suscipit a convallis id, Integer convallis, velit ac venenatis fringilla, turpis dui varius dolor, eu viverra tellus lacus vitae mi. Sed leo purus, fermentum ut turpis eu, lacinia lacinia lectus. Etiam iaculis mauris eget neque semper commodo. In tempor ornare tortor.
101	Salogel	2	Par defaut	Lorem ipsum dolor sit amet, consectetur adipiscing elit. Aenean sit amet dignissim purus, et consectetur augue. Proin varius lacus ac justo vulputate condimentum. Sed dapibus porttitor mi. Integer felis lacus, ornare vel consequat eu, imperdiet id nunc. In ullamcorper nisl a egestas gravida. Curabitur orci tellus, suscipit a convallis id, Integer convallis, velit ac venenatis fringilla, turpis dui varius dolor, eu viverra tellus lacus vitae mi. Sed leo purus, fermentum ut turpis eu, lacinia lacinia lectus. Etiam iaculis mauris eget neque semper commodo. In tempor ornare tortor.
110	Chevalier Perdu	3	eeee	Lorem ipsum dolor sit amet, consectetur adipiscing elit. Aenean sit amet dignissim purus, et consectetur augue. Proin varius lacus ac justo vulputate condimentum. Sed dapibus porttitor mi. Integer felis lacus, ornare vel consequat eu, imperdiet id nunc. In ullamcorper nisl a egestas gravida. Curabitur orci tellus, suscipit a convallis id, Integer convallis, velit ac venenatis fringilla, turpis dui varius dolor, eu viverra tellus lacus vitae mi. Sed leo purus, fermentum ut turpis eu, lacinia lacinia lectus. Etiam iaculis mauris eget neque semper commodo. In tempor ornare tortor.
111	Salogel	3	dz	Lorem ipsum dolor sit amet, consectetur adipiscing elit. Aenean sit amet dignissim purus, et consectetur augue. Proin varius lacus ac justo vulputate condimentum. Sed dapibus porttitor mi. Integer felis lacus, ornare vel consequat eu, imperdiet id nunc. In ullamcorper nisl a egestas gravida. Curabitur orci tellus, suscipit a convallis id, Integer convallis, velit ac venenatis fringilla, turpis dui varius dolor, eu viverra tellus lacus vitae mi. Sed leo purus, fermentum ut turpis eu, lacinia lacinia lectus. Etiam iaculis mauris eget neque semper commodo. In tempor ornare tortor.
112	Salogel	1	dz	Lorem ipsum dolor sit amet, consectetur adipiscing elit. Aenean sit amet dignissim purus, et consectetur augue. Proin varius lacus ac justo vulputate condimentum. Sed dapibus porttitor mi. Integer felis lacus, ornare vel consequat eu, imperdiet id nunc. In ullamcorper nisl a egestas gravida. Curabitur orci tellus, suscipit a convallis id, Integer convallis, velit ac venenatis fringilla, turpis dui varius dolor, eu viverra tellus lacus vitae mi. Sed leo purus, fermentum ut turpis eu, lacinia lacinia lectus. Etiam iaculis mauris eget neque semper commodo. In tempor ornare tortor.
103	Chevalier Perdu	4	Par defaut	Lorem ipsum dolor sit amet, consectetur adipiscing elit. Aenean sit amet dignissim purus, et consectetur augue. Proin varius lacus ac justo vulputate condimentum. Sed dapibus porttitor mi. Integer felis lacus, ornare vel consequat eu, imperdiet id nunc. In ullamcorper nisl a egestas gravida. Curabitur orci tellus, suscipit a convallis id, Integer convallis, velit ac venenatis fringilla, turpis dui varius dolor, eu viverra tellus lacus vitae mi. Sed leo purus, fermentum ut turpis eu, lacinia lacinia lectus. Etiam iaculis mauris eget neque semper commodo. In tempor ornare tortor.
107	Loup Sauvage	1	Par defaut	Lorem ipsum dolor sit amet, consectetur adipiscing elit. Aenean sit amet dignissim purus, et consectetur augue. Proin varius lacus ac justo vulputate condimentum. Sed dapibus porttitor mi. Integer felis lacus, ornare vel consequat eu, imperdiet id nunc. In ullamcorper nisl a egestas gravida. Curabitur orci tellus, suscipit a convallis id, Integer convallis, velit ac venenatis fringilla, turpis dui varius dolor, eu viverra tellus lacus vitae mi. Sed leo purus, fermentum ut turpis eu, lacinia lacinia lectus. Etiam iaculis mauris eget neque semper commodo. In tempor ornare tortor.
105	Legolas	1	Par defaut	Lorem ipsum dolor sit amet, consectetur adipiscing elit. Aenean sit amet dignissim purus, et consectetur augue. Proin varius lacus ac justo vulputate condimentum. Sed dapibus porttitor mi. Integer felis lacus, ornare vel consequat eu, imperdiet id nunc. In ullamcorper nisl a egestas gravida. Curabitur orci tellus, suscipit a convallis id, Integer convallis, velit ac venenatis fringilla, turpis dui varius dolor, eu viverra tellus lacus vitae mi. Sed leo purus, fermentum ut turpis eu, lacinia lacinia lectus. Etiam iaculis mauris eget neque semper commodo. In tempor ornare tortor.
106	Golem Magique	1	Par defaut	Lorem ipsum dolor sit amet, consectetur adipiscing elit. Aenean sit amet dignissim purus, et consectetur augue. Proin varius lacus ac justo vulputate condimentum. Sed dapibus porttitor mi. Integer felis lacus, ornare vel consequat eu, imperdiet id nunc. In ullamcorper nisl a egestas gravida. Curabitur orci tellus, suscipit a convallis id, Integer convallis, velit ac venenatis fringilla, turpis dui varius dolor, eu viverra tellus lacus vitae mi. Sed leo purus, fermentum ut turpis eu, lacinia lacinia lectus. Etiam iaculis mauris eget neque semper commodo. In tempor ornare tortor.
108	Loup Sauvage	1	Par defaut	Lorem ipsum dolor sit amet, consectetur adipiscing elit. Aenean sit amet dignissim purus, et consectetur augue. Proin varius lacus ac justo vulputate condimentum. Sed dapibus porttitor mi. Integer felis lacus, ornare vel consequat eu, imperdiet id nunc. In ullamcorper nisl a egestas gravida. Curabitur orci tellus, suscipit a convallis id, Integer convallis, velit ac venenatis fringilla, turpis dui varius dolor, eu viverra tellus lacus vitae mi. Sed leo purus, fermentum ut turpis eu, lacinia lacinia lectus. Etiam iaculis mauris eget neque semper commodo. In tempor ornare tortor.
114	Chevalier Perdu	3	Par defaut	Lorem ipsum dolor sit amet, consectetur adipiscing elit. Aenean sit amet dignissim purus, et consectetur augue. Proin varius lacus ac justo vulputate condimentum. Sed dapibus porttitor mi. Integer felis lacus, ornare vel consequat eu, imperdiet id nunc. In ullamcorper nisl a egestas gravida. Curabitur orci tellus, suscipit a convallis id, Integer convallis, velit ac venenatis fringilla, turpis dui varius dolor, eu viverra tellus lacus vitae mi. Sed leo purus, fermentum ut turpis eu, lacinia lacinia lectus. Etiam iaculis mauris eget neque semper commodo. In tempor ornare tortor.
102	Dragon Gentil	3	Par defaut	
104	Roi des Chiens	3	vvegvev	efegeq<g<g
117	Roi des Chiens	3	vvegvev	efegeq<g<g
118	Roi des Chiens	6	vvegvev	efegeq<g<g
119	Chevalier Perdu	3	test	Lorem ipsum dolor sit amet, consectetur adipiscing elit. Aenean sit amet dignissim purus, et consectetur augue. Proin varius lacus ac justo vulputate condimentum. Sed dapibus porttitor mi. Integer felis lacus, ornare vel consequat eu, imperdiet id nunc. In ullamcorper nisl a egestas gravida. Curabitur orci tellus, suscipit a convallis id, Integer convallis, velit ac venenatis fringilla, turpis dui varius dolor, eu viverra tellus lacus vitae mi. Sed leo purus, fermentum ut turpis eu, lacinia lacinia lectus. Etiam iaculis mauris eget neque semper commodo. In tempor ornare tortor.
\.


--
-- Data for Name: est_type; Type: TABLE DATA; Schema: public; Owner: cshamaloow
--

COPY public.est_type (nom, nom_type) FROM stdin;
Legolas	Elfe
Legolas	Archer
Salogel	Monstre
Salogel	Dragon
Dragon Gentil	Dragon
Chevalier Perdu	Chevalier
Dragon de Feu	Dragon
Dragon de Feu	Monstre
Chevalier Argent	Chevalier
Mage Sombre	Mage
Mage Sombre	Sombre
Archère Elfique	Elfe
Archère Elfique	Archer
Golem de Pierre	Golem
Golem de Pierre	Monstre
Roi des Ombres	Roi
Roi des Ombres	Ombres
Monstre Aquatique	Monstre
Monstre Aquatique	Aquatique
Loup Sauvage	Loup
Loup Sauvage	Sauvage
Chevalier Enflammé	Chevalier
Chevalier Enflammé	Enflammé
Sorcière des Vents	Sorcière
Sorcière des Vents	Vent
Golem de Glace	Golem
Golem de Glace	Glace
Dragon Électrique	Dragon
Dragon Électrique	Électrique
Chevalier Fantôme	Chevalier
Chevalier Fantôme	Fantôme
Archer Noir	Archer
Archer Noir	Noir
Roi des Dragons	Roi
Roi des Dragons	Dragon
Légionnaire Céleste	Légionnaire
Légionnaire Céleste	Céleste
Spectre de la Nuit	Spectre
Spectre de la Nuit	Ombre
Basilic Doré	Basilic
Garde du Royaume	Garde
Garde du Royaume	Royaume
Mage des Ombres	Mage
Mage des Ombres	Ombres
Sphinx Mystique	Sphinx
Sphinx Mystique	Mystique
Troll des Cavernes	Troll
Troll des Cavernes	Caverne
Elfe des Bois	Elfe
Elfe des Bois	Bois
Sorcier du Vent	Sorcier
Sorcier du Vent	Vent
Berserker Sauvage	Berserker
Berserker Sauvage	Sauvage
Titan de Fer	Titan
Titan de Fer	Fer
Anubis le Démon	Démon
Anubis le Démon	Anubis
Fée Magique	Fée
Fée Magique	Magique
Démon Infernal	Démon
Démon Infernal	Infernal
Nécromancien	Nécromancien
Valkyrie	Valkyrie
Dragon Ancien	Dragon
Dragon Ancien	Ancien
Sable de Tempête	Sable
Sable de Tempête	Tempête
Serpent Géant	Serpent
Serpent Géant	Géant
Golem Magique	Golem
Golem Magique	Magique
Shaman Elfe	Shaman
Shaman Elfe	Elfe
Homme-Rat	Homme
Homme-Rat	Rat
Garde de Fer	Garde
Garde de Fer	Fer
Faucheuse Nocturne	Faucheuse
Faucheuse Nocturne	Nocturne
Faucon Royal	Faucon
Faucon Royal	Royal
Fureur du Dragon	Dragon
Fureur du Dragon	Fureur
Druidessa	Druidessa
Druidessa	Véritable
Ombre de Guerre	Ombre
Ombre de Guerre	Guerre
Licorne Magique	Licorne
Licorne Magique	Magique
Maître des Éléments	Maître
Maître des Éléments	Éléments
Garde Souterraine	Garde
Garde Souterraine	Souterraine
Roi des Cieux	Roi
Roi des Cieux	Cieux
Sphinx Doré	Sphinx
Sphinx Doré	Doré
Spectre Energie	Spectre
Spectre Energie	Energie
Golem de Métal	Golem
Golem de Métal	Métal
Vampire Immortel	Vampire
Vampire Immortel	Immortel
Soldat Élite	Soldat
Soldat Élite	Élite
Titan du Vent	Titan
Titan du Vent	Vent
Berserker Infernal	Berserker
Berserker Infernal	Infernal
Démon Céleste	Démon
Démon Céleste	Céleste
Fée or	Fée
Fée or	Or
Golem Céleste	Golem
Golem Céleste	Céleste
Élémentaire de Feu	Élémentaire
Élémentaire de Feu	Feu
Mage de Lumière	Mage
Mage de Lumière	Lumière
Légionnaire de Fer	Légionnaire
Légionnaire de Fer	Fer
Basilic des Cavernes	Basilic
Basilic des Cavernes	Caverne
Dragon Mystique	Dragon
Dragon Mystique	Mystique
Kitsune Enragée	Kitsune
Kitsune Enragée	Enragée
Sorcière Obscurité	Sorcière
Sorcière Obscurité	Obscurité
Golem de Magie	Golem
Golem de Magie	Magie
Tigre Sauvage	Tigre
Tigre Sauvage	Sauvage
Ninja Fantôme	Ninja
Ninja Fantôme	Fantôme
Guerrier Céleste	Guerrier
Guerrier Céleste	Céleste
Dragon Sombre	Dragon
Dragon Sombre	Sombre
Sphinx Argent	Sphinx
Sphinx Argent	Argent
Chevalier Spectral	Chevalier
Chevalier Spectral	Spectral
Cobra Empoisonné	Cobra
Cobra Empoisonné	Empoisonné
Loup Fantôme	Loup
Loup Fantôme	Fantôme
Druide Sauvage	Druide
Druide Sauvage	Sauvage
Sirène Enchanteresse	Sirène
Sirène Enchanteresse	Enchanteresse
Chevalier Solaire	Chevalier
Chevalier Solaire	Solaire
Golem de Flamme	Golem
Golem de Flamme	Flamme
\.


--
-- Data for Name: joueur; Type: TABLE DATA; Schema: public; Owner: cshamaloow
--

COPY public.joueur (id_joueur, pseudo, email, mdp, uav) FROM stdin;
1	helloworld	helloworld@mail.com	$2b$12$yWXQ6yDWazir/gHc9ZtyIuzJElXT1Ad72Xa5BTgkXZ5YX0Yv64hgS	5000
2	ske	ske@gmail.com	$2b$12$yWXQ6yDWazir/gHc9ZtyIuzJElXT1Ad72Xa5BTgkXZ5YX0Yv64hgS	1000000
4	bot1	jesuispasunbot@jsp1b.com	$2b$12$yWXQ6yDWazir/gHc9ZtyIuzJElXT1Ad72Xa5BTgkXZ5YX0Yv64hgS	10
5	bot2	freredebot1@jsp1b.com	$2b$12$yWXQ6yDWazir/gHc9ZtyIuzJElXT1Ad72Xa5BTgkXZ5YX0Yv64hgS	11
3	ac	ac@gmail.com	$2b$12$yWXQ6yDWazir/gHc9ZtyIuzJElXT1Ad72Xa5BTgkXZ5YX0Yv64hgS	999992
6	aaa	aa@gmail.com	$2b$12$yWXQ6yDWazir/gHc9ZtyIuzJElXT1Ad72Xa5BTgkXZ5YX0Yv64hgS	10
7	aaaa	aca@gmail.com	$2b$12$yWXQ6yDWazir/gHc9ZtyIuzJElXT1Ad72Xa5BTgkXZ5YX0Yv64hgS	10
\.


--
-- Data for Name: mana; Type: TABLE DATA; Schema: public; Owner: cshamaloow
--

COPY public.mana (couleur) FROM stdin;
jaune
bleu
noir
rouge
vert
\.


--
-- Data for Name: suggérer; Type: TABLE DATA; Schema: public; Owner: cshamaloow
--

COPY public."suggérer" (id_joueur, id_deck, "carte_retirée", "carte_ajoutée", id_proprio) FROM stdin;
3	111	Legolas	Roi des Chiens	3
\.


--
-- Data for Name: type; Type: TABLE DATA; Schema: public; Owner: cshamaloow
--

COPY public.type (nom_type) FROM stdin;
Elfe
Archer
Monstre
Dragon
Chevalier
Roi
Mage
Ombres
Aquatique
Loup
Sauvage
Sorcière
Vent
Glace
Électrique
Fantôme
Noir
Légionnaire
Spectre
Basilic
Garde
Royaume
Mystique
Troll
Bois
Golem
Berserker
Titan
Fer
Anubis
Sphinx
Fée
Sorcier
Rat
Faucheuse
Faucon
Energie
Enflammé
Vampire
Soldat
Ombre
Démon
Magique
Infernal
Nécromancien
Valkyrie
Ancien
Sable
Tempête
Serpent
Géant
Shaman
Homme
Nocturne
Royal
Fureur
Druidessa
Véritable
Guerre
Licorne
Maître
Éléments
Souterraine
Cieux
Doré
Énergie
Métal
Immortel
Élite
Céleste
Or
Lumière
Caverne
Enragée
Obscurité
Magie
Tigre
Sombre
Élémentaire
Feu
Kitsune
Argent
Spectral
Ninja
Empoisonné
Sirène
Enchanteresse
Solaire
Cobra
Druide
Guerrier
Flamme
\.


--
-- Name: deck_id_deck_seq; Type: SEQUENCE SET; Schema: public; Owner: cshamaloow
--

SELECT pg_catalog.setval('public.deck_id_deck_seq', 119, true);


--
-- Name: joueur_id_joueur_seq; Type: SEQUENCE SET; Schema: public; Owner: cshamaloow
--

SELECT pg_catalog.setval('public.joueur_id_joueur_seq', 7, true);


--
-- Name: carte carte_pkey; Type: CONSTRAINT; Schema: public; Owner: cshamaloow
--

ALTER TABLE ONLY public.carte
    ADD CONSTRAINT carte_pkey PRIMARY KEY (nom);


--
-- Name: collectionne collectionne_pkey; Type: CONSTRAINT; Schema: public; Owner: cshamaloow
--

ALTER TABLE ONLY public.collectionne
    ADD CONSTRAINT collectionne_pkey PRIMARY KEY (nom, id_joueur);


--
-- Name: confronte confronte_pkey; Type: CONSTRAINT; Schema: public; Owner: cshamaloow
--

ALTER TABLE ONLY public.confronte
    ADD CONSTRAINT confronte_pkey PRIMARY KEY (id_deck_vainqueur, id_deck_perdant, date_);


--
-- Name: contient contient_pkey; Type: CONSTRAINT; Schema: public; Owner: cshamaloow
--

ALTER TABLE ONLY public.contient
    ADD CONSTRAINT contient_pkey PRIMARY KEY (nom, id_deck);


--
-- Name: cout cout_pkey; Type: CONSTRAINT; Schema: public; Owner: cshamaloow
--

ALTER TABLE ONLY public.cout
    ADD CONSTRAINT cout_pkey PRIMARY KEY (nom, couleur);


--
-- Name: deck deck_pkey; Type: CONSTRAINT; Schema: public; Owner: cshamaloow
--

ALTER TABLE ONLY public.deck
    ADD CONSTRAINT deck_pkey PRIMARY KEY (id_deck);


--
-- Name: joueur email_unique; Type: CONSTRAINT; Schema: public; Owner: cshamaloow
--

ALTER TABLE ONLY public.joueur
    ADD CONSTRAINT email_unique UNIQUE (email);


--
-- Name: est_type est_type_pkey; Type: CONSTRAINT; Schema: public; Owner: cshamaloow
--

ALTER TABLE ONLY public.est_type
    ADD CONSTRAINT est_type_pkey PRIMARY KEY (nom, nom_type);


--
-- Name: joueur joueur_email_key; Type: CONSTRAINT; Schema: public; Owner: cshamaloow
--

ALTER TABLE ONLY public.joueur
    ADD CONSTRAINT joueur_email_key UNIQUE (email);


--
-- Name: joueur joueur_pkey; Type: CONSTRAINT; Schema: public; Owner: cshamaloow
--

ALTER TABLE ONLY public.joueur
    ADD CONSTRAINT joueur_pkey PRIMARY KEY (id_joueur);


--
-- Name: mana mana_couleur_key; Type: CONSTRAINT; Schema: public; Owner: cshamaloow
--

ALTER TABLE ONLY public.mana
    ADD CONSTRAINT mana_couleur_key UNIQUE (couleur);


--
-- Name: suggérer suggérer_pkey; Type: CONSTRAINT; Schema: public; Owner: cshamaloow
--

ALTER TABLE ONLY public."suggérer"
    ADD CONSTRAINT "suggérer_pkey" PRIMARY KEY (id_joueur, id_deck, "carte_retirée", "carte_ajoutée");


--
-- Name: type type_pkey; Type: CONSTRAINT; Schema: public; Owner: cshamaloow
--

ALTER TABLE ONLY public.type
    ADD CONSTRAINT type_pkey PRIMARY KEY (nom_type);


--
-- Name: collectionne collectionne_id_joueur_fkey; Type: FK CONSTRAINT; Schema: public; Owner: cshamaloow
--

ALTER TABLE ONLY public.collectionne
    ADD CONSTRAINT collectionne_id_joueur_fkey FOREIGN KEY (id_joueur) REFERENCES public.joueur(id_joueur) ON DELETE CASCADE;


--
-- Name: collectionne collectionne_nom_fkey; Type: FK CONSTRAINT; Schema: public; Owner: cshamaloow
--

ALTER TABLE ONLY public.collectionne
    ADD CONSTRAINT collectionne_nom_fkey FOREIGN KEY (nom) REFERENCES public.carte(nom) ON DELETE CASCADE;


--
-- Name: confronte confronte_id_deck_perdant_fkey; Type: FK CONSTRAINT; Schema: public; Owner: cshamaloow
--

ALTER TABLE ONLY public.confronte
    ADD CONSTRAINT confronte_id_deck_perdant_fkey FOREIGN KEY (id_deck_perdant) REFERENCES public.deck(id_deck) ON DELETE CASCADE;


--
-- Name: confronte confronte_id_deck_vainqueur_fkey; Type: FK CONSTRAINT; Schema: public; Owner: cshamaloow
--

ALTER TABLE ONLY public.confronte
    ADD CONSTRAINT confronte_id_deck_vainqueur_fkey FOREIGN KEY (id_deck_vainqueur) REFERENCES public.deck(id_deck) ON DELETE CASCADE;


--
-- Name: contient contient_id_deck_fkey; Type: FK CONSTRAINT; Schema: public; Owner: cshamaloow
--

ALTER TABLE ONLY public.contient
    ADD CONSTRAINT contient_id_deck_fkey FOREIGN KEY (id_deck) REFERENCES public.deck(id_deck) ON DELETE CASCADE;


--
-- Name: contient contient_nom_fkey; Type: FK CONSTRAINT; Schema: public; Owner: cshamaloow
--

ALTER TABLE ONLY public.contient
    ADD CONSTRAINT contient_nom_fkey FOREIGN KEY (nom) REFERENCES public.carte(nom) ON DELETE CASCADE;


--
-- Name: cout cout_couleur_fkey; Type: FK CONSTRAINT; Schema: public; Owner: cshamaloow
--

ALTER TABLE ONLY public.cout
    ADD CONSTRAINT cout_couleur_fkey FOREIGN KEY (couleur) REFERENCES public.mana(couleur) ON DELETE CASCADE;


--
-- Name: cout cout_nom_fkey; Type: FK CONSTRAINT; Schema: public; Owner: cshamaloow
--

ALTER TABLE ONLY public.cout
    ADD CONSTRAINT cout_nom_fkey FOREIGN KEY (nom) REFERENCES public.carte(nom) ON DELETE CASCADE;


--
-- Name: deck deck_id_joueur_fkey; Type: FK CONSTRAINT; Schema: public; Owner: cshamaloow
--

ALTER TABLE ONLY public.deck
    ADD CONSTRAINT deck_id_joueur_fkey FOREIGN KEY (id_joueur) REFERENCES public.joueur(id_joueur) ON DELETE CASCADE;


--
-- Name: deck deck_nom_général_fkey; Type: FK CONSTRAINT; Schema: public; Owner: cshamaloow
--

ALTER TABLE ONLY public.deck
    ADD CONSTRAINT "deck_nom_général_fkey" FOREIGN KEY ("nom_général") REFERENCES public.carte(nom) ON DELETE CASCADE;


--
-- Name: est_type est_type_nom_fkey; Type: FK CONSTRAINT; Schema: public; Owner: cshamaloow
--

ALTER TABLE ONLY public.est_type
    ADD CONSTRAINT est_type_nom_fkey FOREIGN KEY (nom) REFERENCES public.carte(nom) ON DELETE CASCADE;


--
-- Name: est_type est_type_nom_type_fkey; Type: FK CONSTRAINT; Schema: public; Owner: cshamaloow
--

ALTER TABLE ONLY public.est_type
    ADD CONSTRAINT est_type_nom_type_fkey FOREIGN KEY (nom_type) REFERENCES public.type(nom_type) ON DELETE CASCADE;


--
-- Name: suggérer fk_suggérer_joueur; Type: FK CONSTRAINT; Schema: public; Owner: cshamaloow
--

ALTER TABLE ONLY public."suggérer"
    ADD CONSTRAINT "fk_suggérer_joueur" FOREIGN KEY (id_proprio) REFERENCES public.joueur(id_joueur);


--
-- Name: suggérer suggérer_carte_ajoutée_fkey; Type: FK CONSTRAINT; Schema: public; Owner: cshamaloow
--

ALTER TABLE ONLY public."suggérer"
    ADD CONSTRAINT "suggérer_carte_ajoutée_fkey" FOREIGN KEY ("carte_ajoutée") REFERENCES public.carte(nom) ON DELETE CASCADE;


--
-- Name: suggérer suggérer_carte_retirée_fkey; Type: FK CONSTRAINT; Schema: public; Owner: cshamaloow
--

ALTER TABLE ONLY public."suggérer"
    ADD CONSTRAINT "suggérer_carte_retirée_fkey" FOREIGN KEY ("carte_retirée") REFERENCES public.carte(nom) ON DELETE CASCADE;


--
-- Name: suggérer suggérer_id_deck_fkey; Type: FK CONSTRAINT; Schema: public; Owner: cshamaloow
--

ALTER TABLE ONLY public."suggérer"
    ADD CONSTRAINT "suggérer_id_deck_fkey" FOREIGN KEY (id_deck) REFERENCES public.deck(id_deck) ON DELETE CASCADE;


--
-- Name: suggérer suggérer_id_joueur_fkey; Type: FK CONSTRAINT; Schema: public; Owner: cshamaloow
--

ALTER TABLE ONLY public."suggérer"
    ADD CONSTRAINT "suggérer_id_joueur_fkey" FOREIGN KEY (id_joueur) REFERENCES public.joueur(id_joueur) ON DELETE CASCADE;


--
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: cshamaloow
--

REVOKE USAGE ON SCHEMA public FROM PUBLIC;


--
-- PostgreSQL database dump complete
--

