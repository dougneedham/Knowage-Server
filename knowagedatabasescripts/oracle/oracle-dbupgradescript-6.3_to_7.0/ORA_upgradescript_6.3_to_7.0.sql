--- START ---
ALTER TABLE SBI_I18N_MESSAGES RENAME TO SBI_I18N_MESSAGES_OLD;

CREATE TABLE SBI_I18N_MESSAGES
AS (SELECT CAST(ROWNUM AS NUMBER(38, 0)) ID, M.*
FROM DUAL, SBI_I18N_MESSAGES_OLD M);

DROP TABLE SBI_I18N_MESSAGES_OLD;

ALTER TABLE SBI_I18N_MESSAGES ADD CONSTRAINT PK_SBI_I18N_MESSAGES PRIMARY KEY (ID);
ALTER TABLE SBI_I18N_MESSAGES ADD CONSTRAINT FK_SBI_I18N_MESSAGES FOREIGN KEY (LANGUAGE_CD) REFERENCES SBI_DOMAINS (VALUE_ID);
ALTER TABLE SBI_I18N_MESSAGES ADD CONSTRAINT SBI_I18N_MESSAGES_UNIQUE UNIQUE (LANGUAGE_CD, LABEL, ORGANIZATION);

INSERT INTO hibernate_sequences VALUES ('SBI_I18N_MESSAGES',
                                                            (SELECT NVL(MAX(m.ID) + 1, 1) FROM SBI_I18N_MESSAGES m));  
COMMIT;                                                            
--- END ---                    

CREATE UNIQUE INDEX XAK2SBI_DATA_SET ON SBI_DATA_SET(NAME, VERSION_NUM, ORGANIZATION);

ALTER TABLE SBI_ATTRIBUTE ADD (LOV_ID INTEGER NULL,ALLOW_USER SMALLINT  DEFAULT '1',MULTIVALUE SMALLINT  DEFAULT '0',SYNTAX SMALLINT NULL, 
									  VALUE_TYPE_ID INTEGER NULL, VALUE_TYPE_CD VARCHAR2(20), VALUE_TYPE VARCHAR2(50));
ALTER TABLE SBI_ATTRIBUTE ADD CONSTRAINT FK_LOV FOREIGN KEY (LOV_ID) REFERENCES SBI_LOV(LOV_ID);
ALTER TABLE SBI_ATTRIBUTE ADD CONSTRAINT ENUM_TYPE CHECK (VALUE_TYPE IN('STRING','DATE','NUM'));

ALTER TABLE SBI_ATTRIBUTE MODIFY (DESCRIPTION VARCHAR2(500) NULL);

ALTER TABLE SBI_EVENTS_LOG ADD EVENT_TYPE VARCHAR2(50) DEFAULT 'SCHEDULER' NOT NULL;

UPDATE SBI_EVENTS_LOG SET EVENT_TYPE = (
CASE HANDLER 
	WHEN 'it.eng.spagobi.events.handlers.DefaultEventPresentationHandler' THEN 'SCHEDULER'
	WHEN 'it.eng.spagobi.events.handlers.CommonjEventPresentationHandler' THEN 'COMMONJ'
	WHEN 'it.eng.spagobi.events.handlers.TalendEventPresentationHandler' THEN 'ETL'
	WHEN 'it.eng.spagobi.events.handlers.WekaEventPresentationHandler' THEN 'DATA_MINING'
END
);
commit;

ALTER TABLE SBI_EVENTS_LOG DROP COLUMN HANDLER;

ALTER TABLE SBI_OUTPUT_PARAMETER MODIFY FORMAT_VALUE VARCHAR2(30);
---BEGIN---
CREATE TABLE SBI_METAMODEL_PAR (
	METAMODEL_PAR_ID INTEGER NOT NULL ,
	PAR_ID INTEGER NOT NULL ,
	METAMODEL_ID INTEGER NOT NULL ,
	LABEL VARCHAR2 (40) NOT NULL ,
	REQ_FL SMALLINT,
	MOD_FL SMALLINT,
	VIEW_FL SMALLINT,
	MULT_FL SMALLINT,
	PROG INTEGER NOT NULL ,
	PARURL_NM VARCHAR2 (20),
	PRIORITY INTEGER,
	COL_SPAN             INTEGER,
    THICK_PERC           INTEGER,
	USER_IN              VARCHAR2(100) NOT NULL,
    USER_UP              VARCHAR2(100),
    USER_DE              VARCHAR2(100),
    TIME_IN              TIMESTAMP NOT NULL,
       TIME_UP               TIMESTAMP DEFAULT NULL,
       TIME_DE               TIMESTAMP DEFAULT NULL,
    SBI_VERSION_IN       VARCHAR2(10),
    SBI_VERSION_UP       VARCHAR2(10),
    SBI_VERSION_DE       VARCHAR2(10),
    META_VERSION         VARCHAR2(100),
    ORGANIZATION         VARCHAR2(20),
PRIMARY KEY (METAMODEL_PAR_ID) 
);

ALTER TABLE SBI_METAMODEL_PAR ADD CONSTRAINT SBI_METAMODEL_PAR_1 FOREIGN KEY (METAMODEL_ID) REFERENCES SBI_META_MODELS (ID);
ALTER TABLE SBI_METAMODEL_PAR ADD CONSTRAINT SBI_METAMODEL_PAR_2 FOREIGN KEY (PAR_ID) REFERENCES SBI_PARAMETERS (PAR_ID);

---END---

---Begin---

CREATE TABLE SBI_METAMODEL_PARUSE (
		PARUSE_ID			INTEGER NOT NULL,
		METAMODEL_PAR_ID    INTEGER NOT NULL,
		USE_ID              INTEGER NOT NULL,
		METAMODEL_PAR_FATHER_ID   INTEGER NOT NULL,
		FILTER_OPERATION    VARCHAR2(20) NOT NULL,
		PROG 				INTEGER NOT NULL,
		FILTER_COLUMN       VARCHAR2(30) NOT NULL,
		PRE_CONDITION 		VARCHAR2(10),
	    POST_CONDITION 		VARCHAR2(10),
	    LOGIC_OPERATOR 		VARCHAR2(10),
        USER_IN             VARCHAR2(100) NOT NULL,
        USER_UP             VARCHAR2(100),
        USER_DE             VARCHAR2(100),
        TIME_IN             TIMESTAMP NOT NULL,
       TIME_UP               TIMESTAMP DEFAULT NULL,
       TIME_DE               TIMESTAMP DEFAULT NULL,
        SBI_VERSION_IN      VARCHAR2(10),
        SBI_VERSION_UP      VARCHAR2(10),
        SBI_VERSION_DE      VARCHAR2(10),
        META_VERSION        VARCHAR2(100),
        ORGANIZATION        VARCHAR2(20),    
	    PRIMARY KEY(PARUSE_ID)
);

ALTER TABLE SBI_METAMODEL_PARUSE					ADD CONSTRAINT FK_SBI_METAMODEL_PARUSE_1 					FOREIGN KEY (METAMODEL_PAR_ID) 			REFERENCES SBI_METAMODEL_PAR (METAMODEL_PAR_ID) ;
ALTER TABLE SBI_METAMODEL_PARUSE 					ADD CONSTRAINT FK_SBI_METAMODEL_PARUSE_2 					FOREIGN KEY (USE_ID) 				REFERENCES SBI_PARUSE (USE_ID) 	;
ALTER TABLE SBI_METAMODEL_PARUSE 					ADD CONSTRAINT FK_SBI_METAMODEL_PARUSE_3 					FOREIGN KEY (METAMODEL_PAR_FATHER_ID)		REFERENCES SBI_METAMODEL_PAR (METAMODEL_PAR_ID);

CREATE TABLE SBI_METAMODEL_PARVIEW (
	PARVIEW_ID INTEGER NOT NULL,	
    METAMODEL_PAR_ID INTEGER NOT NULL,
    METAMODEL_PAR_FATHER_ID  INTEGER NOT NULL,
    OPERATION  VARCHAR(20) NOT NULL,
    COMPARE_VALUE  VARCHAR(200) NOT NULL,
    VIEW_LABEL  VARCHAR(50),
    PROG INTEGER,
       USER_IN              VARCHAR(100) NOT NULL,
       USER_UP              VARCHAR(100),
       USER_DE              VARCHAR(100),
       TIME_IN              TIMESTAMP NOT NULL,
       TIME_UP               TIMESTAMP DEFAULT NULL,
       TIME_DE               TIMESTAMP DEFAULT NULL,
       SBI_VERSION_IN       VARCHAR(10),
       SBI_VERSION_UP       VARCHAR(10),
       SBI_VERSION_DE       VARCHAR(10),
       META_VERSION         VARCHAR(100),
       ORGANIZATION         VARCHAR(20),    
  PRIMARY KEY (PARVIEW_ID)
) ;

ALTER TABLE SBI_METAMODEL_PARVIEW 				ADD CONSTRAINT FK_SBI_METAMODEL_PARVIEW_1 				FOREIGN KEY (METAMODEL_PAR_ID) 			REFERENCES SBI_METAMODEL_PAR (METAMODEL_PAR_ID);
ALTER TABLE SBI_METAMODEL_PARVIEW 				ADD CONSTRAINT FK_SBI_METAMODEL_PARVIEW_2 				FOREIGN KEY (METAMODEL_PAR_FATHER_ID)		REFERENCES SBI_METAMODEL_PAR (METAMODEL_PAR_ID);


ALTER TABLE SBI_METAMODEL_PAR 
MODIFY REQ_FL SMALLINT DEFAULT 0
MODIFY MOD_FL SMALLINT DEFAULT 0
MODIFY VIEW_FL SMALLINT DEFAULT 1
MODIFY MULT_FL SMALLINT DEFAULT 0 ;

ALTER TABLE SBI_OBJ_PAR 
MODIFY REQ_FL NUMBER DEFAULT 0
MODIFY MOD_FL NUMBER DEFAULT 0
MODIFY VIEW_FL NUMBER DEFAULT 1
MODIFY MULT_FL NUMBER DEFAULT 0;

ALTER TABLE SBI_FEDERATION_DEFINITION ADD OWNER VARCHAR2(100) NULL;
--END--

--BEGIN--
ALTER TABLE SBI_OBJ_PARVIEW RENAME TO SBI_OBJ_PARVIEW_OLD;

CREATE TABLE SBI_OBJ_PARVIEW AS 
SELECT ROWNUM AS PARVIEW_ID, T.*
FROM SBI_OBJ_PARVIEW_OLD T;

select * from SBI_OBJ_PARUSE;

ALTER TABLE SBI_OBJ_PARVIEW ADD CONSTRAINT PK_SBI_OBJ_PARVIEW PRIMARY KEY(PARVIEW_ID);
ALTER TABLE SBI_OBJ_PARVIEW ADD CONSTRAINT FK_SBI_OBJ_PARVIEW_1 FOREIGN KEY (OBJ_PAR_ID) REFERENCES SBI_OBJ_PAR (OBJ_PAR_ID);
ALTER TABLE SBI_OBJ_PARVIEW ADD CONSTRAINT FK_SBI_OBJ_PARVIEW_2 FOREIGN KEY (OBJ_PAR_FATHER_ID) REFERENCES SBI_OBJ_PAR (OBJ_PAR_ID);

INSERT INTO hibernate_sequences VALUES ('SBI_OBJ_PARVIEW',
                                                            (SELECT NVL(MAX(t.PARVIEW_ID) + 1, 1) FROM SBI_OBJ_PARVIEW t));

DROP TABLE SBI_OBJ_PARVIEW_OLD;




ALTER TABLE SBI_OBJ_PARUSE RENAME TO SBI_OBJ_PARUSE_OLD;

CREATE TABLE SBI_OBJ_PARUSE AS 
SELECT ROWNUM AS PARUSE_ID, T.*
FROM SBI_OBJ_PARUSE_OLD T;

ALTER TABLE SBI_OBJ_PARUSE ADD CONSTRAINT PK_SBI_OBJ_PARUSE PRIMARY KEY(PARUSE_ID);
ALTER TABLE SBI_OBJ_PARUSE ADD CONSTRAINT FK_SBI_OBJ_PARUSE_1 FOREIGN KEY (OBJ_PAR_ID) REFERENCES SBI_OBJ_PAR (OBJ_PAR_ID);
ALTER TABLE SBI_OBJ_PARUSE ADD CONSTRAINT FK_SBI_OBJ_PARUSE_2 FOREIGN KEY (USE_ID) REFERENCES SBI_PARUSE (USE_ID);
ALTER TABLE SBI_OBJ_PARUSE ADD CONSTRAINT FK_SBI_OBJ_PARUSE_3 FOREIGN KEY (OBJ_PAR_FATHER_ID) REFERENCES SBI_OBJ_PAR (OBJ_PAR_ID);

INSERT INTO hibernate_sequences VALUES ('SBI_OBJ_PARUSE',
                                                            (SELECT NVL(MAX(t.PARUSE_ID) + 1, 1) FROM SBI_OBJ_PARUSE t));

DROP TABLE SBI_OBJ_PARUSE_OLD;
--END--

DELETE FROM SBI_ROLE_TYPE_USER_FUNC WHERE ROLE_TYPE_ID = (SELECT VALUE_ID FROM SBI_DOMAINS WHERE VALUE_CD = 'TEST_ROLE') AND USER_FUNCT_ID IN (SELECT USER_FUNCT_ID FROM SBI_USER_FUNC  WHERE  NAME IN ('TIMESPAN', 'FUNCTIONSCATALOGMANAGEMENT','MANAGECROSSNAVIGATION','EVENTSMANAGEMENT'));
COMMIT;

ALTER TABLE SBI_CROSS_NAVIGATION ADD DESCRIPTION VARCHAR2(200);
ALTER TABLE SBI_CROSS_NAVIGATION ADD BREADCRUMB VARCHAR2(200);

CREATE TABLE SBI_METAMODEL_VIEWPOINTS (
VP_ID INTEGER NOT NULL,
METAMODEL_ID INTEGER NOT NULL,
VP_NAME VARCHAR(40) NOT NULL,
VP_OWNER VARCHAR(40) DEFAULT NULL,
VP_DESC VARCHAR(160) DEFAULT NULL,
VP_SCOPE VARCHAR(20) NOT NULL,
VP_VALUE_PARAMS CLOB,
VP_CREATION_DATE TIMESTAMP  DEFAULT CURRENT_TIMESTAMP,
USER_IN VARCHAR(100) NOT NULL,
USER_UP VARCHAR(100) DEFAULT NULL,
USER_DE VARCHAR(100) DEFAULT NULL,
TIME_IN TIMESTAMP  DEFAULT CURRENT_TIMESTAMP NOT NULL,
TIME_UP TIMESTAMP  DEFAULT NULL,
TIME_DE TIMESTAMP  DEFAULT NULL,
SBI_VERSION_IN VARCHAR(10) DEFAULT NULL,
SBI_VERSION_UP VARCHAR(10) DEFAULT NULL,
SBI_VERSION_DE VARCHAR(10) DEFAULT NULL,
META_VERSION VARCHAR(100) DEFAULT NULL,
ORGANIZATION VARCHAR(20) DEFAULT NULL,
PRIMARY KEY (VP_ID)
) ;

ALTER TABLE SBI_METAMODEL_VIEWPOINTS ADD CONSTRAINT FK_SBI_METAMODEL_VIEWPOINTS_1 FOREIGN KEY (METAMODEL_ID) REFERENCES SBI_META_MODELS (ID);
CREATE TABLE SBI_TAG (
	TAG_ID               INTEGER NOT NULL,
	NAME                 VARCHAR(30) NOT NULL,
	USER_IN              VARCHAR(100) NOT NULL,
	USER_UP              VARCHAR(100),
	USER_DE              VARCHAR(100),
	TIME_IN              TIMESTAMP NOT NULL,
	TIME_UP              TIMESTAMP  DEFAULT NULL,
	TIME_DE              TIMESTAMP  DEFAULT NULL,
	SBI_VERSION_IN       VARCHAR(10),
	SBI_VERSION_UP       VARCHAR(10),
	SBI_VERSION_DE       VARCHAR(10),
	META_VERSION         VARCHAR(100),
	ORGANIZATION         VARCHAR(20),
	PRIMARY KEY (TAG_ID),
	CONSTRAINT XAK1SBI_TAG UNIQUE (NAME, ORGANIZATION)
);


CREATE TABLE SBI_DATA_SET_TAG (
	DS_ID                INTEGER NOT NULL,
	VERSION_NUM	     	 INTEGER NOT NULL,
	ORGANIZATION         VARCHAR(20),
	TAG_ID               INTEGER NOT NULL,
	PRIMARY KEY (DS_ID, VERSION_NUM, ORGANIZATION, TAG_ID),
	FOREIGN KEY (TAG_ID) REFERENCES SBI_TAG (TAG_ID) ,
	FOREIGN KEY (DS_ID, VERSION_NUM, ORGANIZATION) REFERENCES SBI_DATA_SET (DS_ID, VERSION_NUM, ORGANIZATION)
	
);
