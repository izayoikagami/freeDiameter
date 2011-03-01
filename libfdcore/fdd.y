/*********************************************************************************************************
* Software License Agreement (BSD License)                                                               *
* Author: Sebastien Decugis <sdecugis@nict.go.jp>							 *
*													 *
* Copyright (c) 2011, WIDE Project and NICT								 *
* All rights reserved.											 *
* 													 *
* Redistribution and use of this software in source and binary forms, with or without modification, are  *
* permitted provided that the following conditions are met:						 *
* 													 *
* * Redistributions of source code must retain the above 						 *
*   copyright notice, this list of conditions and the 							 *
*   following disclaimer.										 *
*    													 *
* * Redistributions in binary form must reproduce the above 						 *
*   copyright notice, this list of conditions and the 							 *
*   following disclaimer in the documentation and/or other						 *
*   materials provided with the distribution.								 *
* 													 *
* * Neither the name of the WIDE Project or NICT nor the 						 *
*   names of its contributors may be used to endorse or 						 *
*   promote products derived from this software without 						 *
*   specific prior written permission of WIDE Project and 						 *
*   NICT.												 *
* 													 *
* THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED *
* WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A *
* PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR *
* ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT 	 *
* LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 	 *
* INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR *
* TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF   *
* ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.								 *
*********************************************************************************************************/

/* Yacc configuration parser.
 *
 * This file defines the grammar of the configuration file.
 * Note that each extension has a separate independant configuration file.
 *
 * Note : This module is NOT thread-safe. All processing must be done from one thread only.
 */

/* For development only : */
%debug 
%error-verbose

%parse-param {struct fd_config * conf}

/* Keep track of location */
%locations 
%pure-parser

%{
#include "fdcore-internal.h"
#include "fdd.tab.h"	/* bug : bison does not define the YYLTYPE before including this bloc, so... */

/* The Lex parser prototype */
int fddlex(YYSTYPE *lvalp, YYLTYPE *llocp);

/* Function to report error */
void yyerror (YYLTYPE *ploc, struct fd_config * conf, char const *s)
{
	if (ploc->first_line != ploc->last_line)
		fprintf(stderr, "%s:%d.%d-%d.%d : %s\n", conf->cnf_file, ploc->first_line, ploc->first_column, ploc->last_line, ploc->last_column, s);
	else if (ploc->first_column != ploc->last_column)
		fprintf(stderr, "%s:%d.%d-%d : %s\n", conf->cnf_file, ploc->first_line, ploc->first_column, ploc->last_column, s);
	else
		fprintf(stderr, "%s:%d.%d : %s\n", conf->cnf_file, ploc->first_line, ploc->first_column, s);
}

int got_peer_noip = 0;
int got_peer_noipv6 = 0;
int got_peer_notcp = 0;
int got_peer_nosctp = 0;

struct peer_info fddpi;

%}

/* Values returned by lex for token */
%union {
	char 		 *string;	/* The string is allocated by strdup in lex.*/
	int		  integer;	/* Store integer values */
}

/* In case of error in the lexical analysis */
%token 		LEX_ERROR

%token <string>	QSTRING
%token <integer> INTEGER

%type <string> 	extconf

%token		IDENTITY
%token		REALM
%token		PORT
%token		SECPORT
%token		NOIP
%token		NOIP6
%token		NOTCP
%token		NOSCTP
%token		PREFERTCP
%token		OLDTLS
%token		NOTLS
%token		SCTPSTREAMS
%token		APPSERVTHREADS
%token		LISTENON
%token		TCTIMER
%token		TWTIMER
%token		NORELAY
%token		LOADEXT
%token		CONNPEER
%token		CONNTO
%token		TLS_CRED
%token		TLS_CA
%token		TLS_CRL
%token		TLS_PRIO
%token		TLS_DH_BITS
%token		TLS_DH_FILE


/* -------------------------------------- */
%%

	/* The grammar definition - Sections blocs. */
conffile:		/* Empty is OK -- for simplicity here, we reject in daemon later */
			| conffile identity
			| conffile realm
			| conffile tctimer
			| conffile twtimer
			| conffile port
			| conffile secport
			| conffile sctpstreams
			| conffile listenon
			| conffile norelay
			| conffile appservthreads
			| conffile noip
			| conffile noip6
			| conffile notcp
			| conffile nosctp
			| conffile prefertcp
			| conffile oldtls
			| conffile loadext
			| conffile connpeer
			| conffile tls_cred
			| conffile tls_ca
			| conffile tls_crl
			| conffile tls_prio
			| conffile tls_dh
			| conffile errors
			{
				yyerror(&yylloc, conf, "An error occurred while parsing the configuration file");
				return EINVAL;
			}
			;

			/* Lexical or syntax error */
errors:			LEX_ERROR
			| error
			;

identity:		IDENTITY '=' QSTRING ';'
			{
				conf->cnf_diamid = $3;
			}
			;

realm:			REALM '=' QSTRING ';'
			{
				conf->cnf_diamrlm = $3;
			}
			;

tctimer:		TCTIMER '=' INTEGER ';'
			{
				CHECK_PARAMS_DO( ($3 > 0),
					{ yyerror (&yylloc, conf, "Invalid value"); YYERROR; } );
				conf->cnf_timer_tc = (unsigned int)$3;
			}
			;

twtimer:		TWTIMER '=' INTEGER ';'
			{
				CHECK_PARAMS_DO( ($3 > 5),
					{ yyerror (&yylloc, conf, "Invalid value"); YYERROR; } );
				conf->cnf_timer_tw = (unsigned int)$3;
			}
			;

port:			PORT '=' INTEGER ';'
			{
				CHECK_PARAMS_DO( ($3 > 0) && ($3 < 1<<16),
					{ yyerror (&yylloc, conf, "Invalid value"); YYERROR; } );
				conf->cnf_port = (uint16_t)$3;
			}
			;

secport:		SECPORT '=' INTEGER ';'
			{
				CHECK_PARAMS_DO( ($3 > 0) && ($3 < 1<<16),
					{ yyerror (&yylloc, conf, "Invalid value"); YYERROR; } );
				conf->cnf_port_tls = (uint16_t)$3;
			}
			;

sctpstreams:		SCTPSTREAMS '=' INTEGER ';'
			{
				CHECK_PARAMS_DO( ($3 > 0) && ($3 < 1<<16),
					{ yyerror (&yylloc, conf, "Invalid value"); YYERROR; } );
				conf->cnf_sctp_str = (uint16_t)$3;
			}
			;

listenon:		LISTENON '=' QSTRING ';'
			{
				struct addrinfo hints, *ai;
				int ret;
				
				memset(&hints, 0, sizeof(hints));
				hints.ai_flags = AI_PASSIVE | AI_NUMERICHOST;
				ret = getaddrinfo($3, NULL, &hints, &ai);
				if (ret) { yyerror (&yylloc, conf, gai_strerror(ret)); YYERROR; }
				CHECK_FCT_DO( fd_ep_add_merge( &conf->cnf_endpoints, ai->ai_addr, ai->ai_addrlen, EP_FL_CONF ), YYERROR );
				freeaddrinfo(ai);
				free($3);
			}
			;

norelay:		NORELAY ';'
			{
				conf->cnf_flags.no_fwd = 1;
			}
			;

appservthreads:		APPSERVTHREADS '=' INTEGER ';'
			{
				CHECK_PARAMS_DO( ($3 > 0) && ($3 < 256),
					{ yyerror (&yylloc, conf, "Invalid value"); YYERROR; } );
				conf->cnf_dispthr = (uint16_t)$3;
			}
			;

noip:			NOIP ';'
			{
				if (got_peer_noipv6) { 
					yyerror (&yylloc, conf, "No_IP conflicts with a ConnectPeer directive No_IPv6."); 
					YYERROR; 
				}
				conf->cnf_flags.no_ip4 = 1;
			}
			;

noip6:			NOIP6 ';'
			{
				if (got_peer_noip) { 
					yyerror (&yylloc, conf, "No_IP conflicts with a ConnectPeer directive No_IP."); 
					YYERROR; 
				}
				conf->cnf_flags.no_ip6 = 1;
			}
			;

notcp:			NOTCP ';'
			{
				#ifdef DISABLE_SCTP
				yyerror (&yylloc, conf, "No_TCP cannot be specified for daemon compiled with DISABLE_SCTP option."); 
				YYERROR; 
				#endif
				if (conf->cnf_flags.no_sctp)
				{
					yyerror (&yylloc, conf, "No_TCP conflicts with No_SCTP directive." ); 
					YYERROR; 
				}
				if (got_peer_nosctp) { 
					yyerror (&yylloc, conf, "No_TCP conflicts with a ConnectPeer directive No_SCTP."); 
					YYERROR; 
				}
				conf->cnf_flags.no_tcp = 1;
			}
			;

nosctp:			NOSCTP ';'
			{
				if (conf->cnf_flags.no_tcp)
				{
					yyerror (&yylloc, conf, "No_SCTP conflicts with No_TCP directive." ); 
					YYERROR; 
				}
				if (got_peer_notcp) { 
					yyerror (&yylloc, conf, "No_SCTP conflicts with a ConnectPeer directive No_TCP.");
					YYERROR;
				}
				conf->cnf_flags.no_sctp = 1;
			}
			;

prefertcp:		PREFERTCP ';'
			{
				conf->cnf_flags.pr_tcp = 1;
			}
			;

oldtls:			OLDTLS ';'
			{
				conf->cnf_flags.tls_alg = 1;
			}
			;

loadext:		LOADEXT '=' QSTRING extconf ';'
			{
				char * fname;
				char * cfname;
				FILE * fd;
				
				/* Try and open the extension file */
				fname = $3;
				fd = fopen(fname, "r");
				if ((fd == NULL) && (*fname != '/')) {
					char * bkp = fname;
					CHECK_MALLOC_DO( fname = malloc( strlen(bkp) + strlen(DEFAULT_EXTENSIONS_PATH) + 2 ),
						{ yyerror (&yylloc, conf, "Not enough memory"); YYERROR; } );
					sprintf(fname, DEFAULT_EXTENSIONS_PATH "/%s", bkp);
					free(bkp);
					fd = fopen(fname, "r");
				}
				if (fd == NULL) {
					int ret = errno;
					TRACE_DEBUG(INFO, "Unable to open extension file %s for reading: %s\n", fname, strerror(ret));
					yyerror (&yylloc, conf, "Error adding extension"); 
					YYERROR;
				}
				fclose(fd);
				
				/* Try and open the configuration file (optional) */
				cfname = $4;
				if (cfname) {
					fd = fopen(cfname, "r");
					if ((fd == NULL) && (*cfname != '/')) {
						char * test;
						CHECK_MALLOC_DO( test = malloc( strlen(cfname) + strlen(DEFAULT_CONF_PATH) + 2 ),
							{ yyerror (&yylloc, conf, "Not enough memory"); YYERROR; } );
						sprintf(test, DEFAULT_CONF_PATH "/%s", cfname);
						fd = fopen(test, "r");
						if (fd) {
							free(cfname);
							cfname=test;
						} else {
							/* This is not an error, we allow an extension to wait for something else than a real conf file. */
							free(test);
						}
					}
					if (fd)
						fclose(fd);
				}
				
				CHECK_FCT_DO( fd_ext_add( fname, cfname ),
					{ yyerror (&yylloc, conf, "Error adding extension"); YYERROR; } );
			}
			;
			
extconf:		/* empty */
			{
				$$ = NULL;
			}
			| ':' QSTRING
			{
				$$ = $2;
			}
			;
			
connpeer:		{
				memset(&fddpi, 0, sizeof(fddpi));
				fddpi.config.pic_flags.persist = PI_PRST_ALWAYS;
				fd_list_init( &fddpi.pi_endpoints, NULL );
			}
			CONNPEER '=' QSTRING peerinfo ';'
			{
				fddpi.pi_diamid = $4;
				CHECK_FCT_DO( fd_peer_add ( &fddpi, conf->cnf_file, NULL, NULL ),
					{ yyerror (&yylloc, conf, "Error adding ConnectPeer information"); YYERROR; } );
					
				/* Now destroy any content in the structure */
				free(fddpi.pi_diamid);
				free(fddpi.config.pic_realm);
				free(fddpi.config.pic_priority);
				while (!FD_IS_LIST_EMPTY(&fddpi.pi_endpoints)) {
					struct fd_list * li = fddpi.pi_endpoints.next;
					fd_list_unlink(li);
					free(li);
				}
			}
			;
			
peerinfo:		/* empty */
			| '{' peerparams '}'
			;
			
peerparams:		/* empty */
			| peerparams NOIP ';'
			{
				if ((conf->cnf_flags.no_ip6) || (fddpi.config.pic_flags.pro3 == PI_P3_IP)) { 
					yyerror (&yylloc, conf, "No_IP conflicts with a No_IPv6 directive.");
					YYERROR;
				}
				got_peer_noip++;
				fddpi.config.pic_flags.pro3 = PI_P3_IPv6;
			}
			| peerparams NOIP6 ';'
			{
				if ((conf->cnf_flags.no_ip4) || (fddpi.config.pic_flags.pro3 == PI_P3_IPv6)) { 
					yyerror (&yylloc, conf, "No_IPv6 conflicts with a No_IP directive.");
					YYERROR;
				}
				got_peer_noipv6++;
				fddpi.config.pic_flags.pro3 = PI_P3_IP;
			}
			| peerparams NOTCP ';'
			{
				#ifdef DISABLE_SCTP
					yyerror (&yylloc, conf, "No_TCP cannot be specified in daemon compiled with DISABLE_SCTP option.");
					YYERROR;
				#endif
				if ((conf->cnf_flags.no_sctp) || (fddpi.config.pic_flags.pro4 == PI_P4_TCP)) { 
					yyerror (&yylloc, conf, "No_TCP conflicts with a No_SCTP directive.");
					YYERROR;
				}
				got_peer_notcp++;
				fddpi.config.pic_flags.pro4 = PI_P4_SCTP;
			}
			| peerparams NOSCTP ';'
			{
				if ((conf->cnf_flags.no_tcp) || (fddpi.config.pic_flags.pro4 == PI_P4_SCTP)) { 
					yyerror (&yylloc, conf, "No_SCTP conflicts with a No_TCP directive.");
					YYERROR;
				}
				got_peer_nosctp++;
				fddpi.config.pic_flags.pro4 = PI_P4_TCP;
			}
			| peerparams PREFERTCP ';'
			{
				fddpi.config.pic_flags.alg = PI_ALGPREF_TCP;
			}
			| peerparams OLDTLS ';'
			{
				fddpi.config.pic_flags.sec |= PI_SEC_TLS_OLD;
			}
			| peerparams NOTLS ';'
			{
				fddpi.config.pic_flags.sec |= PI_SEC_NONE;
			}
			| peerparams REALM '=' QSTRING ';'
			{
				fddpi.config.pic_realm = $4;
			}
			| peerparams PORT '=' INTEGER ';'
			{
				CHECK_PARAMS_DO( ($4 > 0) && ($4 < 1<<16),
					{ yyerror (&yylloc, conf, "Invalid port value"); YYERROR; } );
				fddpi.config.pic_port = (uint16_t)$4;
			}
			| peerparams TCTIMER '=' INTEGER ';'
			{
				fddpi.config.pic_tctimer = $4;
			}
			| peerparams TWTIMER '=' INTEGER ';'
			{
				fddpi.config.pic_twtimer = $4;
			}
			| peerparams TLS_PRIO '=' QSTRING ';'
			{
				fddpi.config.pic_priority = $4;
			}
			| peerparams CONNTO '=' QSTRING ';'
			{
				struct addrinfo hints, *ai;
				int ret;
				int disc = 0;
				
				memset(&hints, 0, sizeof(hints));
				hints.ai_flags = AI_ADDRCONFIG | AI_NUMERICHOST;
				ret = getaddrinfo($4, NULL, &hints, &ai);
				if (ret == EAI_NONAME) {
					/* The name was maybe not numeric, try again */
					disc = EP_FL_DISC;
					hints.ai_flags &= ~ AI_NUMERICHOST;
					ret = getaddrinfo($4, NULL, &hints, &ai);
				}
				if (ret) { yyerror (&yylloc, conf, gai_strerror(ret)); YYERROR; }
				
				CHECK_FCT_DO( fd_ep_add_merge( &fddpi.pi_endpoints, ai->ai_addr, ai->ai_addrlen, EP_FL_CONF | disc ), YYERROR );
				free($4);
				freeaddrinfo(ai);
			}
			;

tls_cred:		TLS_CRED '=' QSTRING ',' QSTRING ';'
			{
				FILE * fd;
				fd = fopen($3, "r");
				if (fd == NULL) {
					int ret = errno;
					TRACE_DEBUG(INFO, "Unable to open certificate file %s for reading: %s\n", $3, strerror(ret));
					yyerror (&yylloc, conf, "Error on file name"); 
					YYERROR;
				}
				fclose(fd);
				fd = fopen($5, "r");
				if (fd == NULL) {
					int ret = errno;
					TRACE_DEBUG(INFO, "Unable to open private key file %s for reading: %s\n", $5, strerror(ret));
					yyerror (&yylloc, conf, "Error on file name"); 
					YYERROR;
				}
				fclose(fd);
				conf->cnf_sec_data.cert_file = $3;
				conf->cnf_sec_data.key_file = $5;
				
				CHECK_GNUTLS_DO( gnutls_certificate_set_x509_key_file( 
							conf->cnf_sec_data.credentials,
							conf->cnf_sec_data.cert_file,
							conf->cnf_sec_data.key_file,
							GNUTLS_X509_FMT_PEM),
						{ yyerror (&yylloc, conf, "Error opening certificate or private key file."); YYERROR; } );
			}
			;

tls_ca:			TLS_CA '=' QSTRING ';'
			{
				FILE * fd;
				fd = fopen($3, "r");
				if (fd == NULL) {
					int ret = errno;
					TRACE_DEBUG(INFO, "Unable to open CA file %s for reading: %s\n", $3, strerror(ret));
					yyerror (&yylloc, conf, "Error on file name"); 
					YYERROR;
				}
				fclose(fd);
				conf->cnf_sec_data.ca_file = $3;
				CHECK_GNUTLS_DO( conf->cnf_sec_data.ca_file_nr += gnutls_certificate_set_x509_trust_file( 
							conf->cnf_sec_data.credentials,
							conf->cnf_sec_data.ca_file,
							GNUTLS_X509_FMT_PEM),
						{ yyerror (&yylloc, conf, "Error setting CA parameters."); YYERROR; } );
			}
			;
			
tls_crl:		TLS_CRL '=' QSTRING ';'
			{
				FILE * fd;
				fd = fopen($3, "r");
				if (fd == NULL) {
					int ret = errno;
					TRACE_DEBUG(INFO, "Unable to open CRL file %s for reading: %s\n", $3, strerror(ret));
					yyerror (&yylloc, conf, "Error on file name"); 
					YYERROR;
				}
				fclose(fd);
				conf->cnf_sec_data.crl_file = $3;
				CHECK_GNUTLS_DO( gnutls_certificate_set_x509_crl_file( 
							conf->cnf_sec_data.credentials,
							conf->cnf_sec_data.ca_file,
							GNUTLS_X509_FMT_PEM),
						{ yyerror (&yylloc, conf, "Error setting CRL parameters."); YYERROR; } );
			}
			;
			
tls_prio:		TLS_PRIO '=' QSTRING ';'
			{
				const char * err_pos = NULL;
				conf->cnf_sec_data.prio_string = $3;
				CHECK_GNUTLS_DO( gnutls_priority_init( 
							&conf->cnf_sec_data.prio_cache,
							conf->cnf_sec_data.prio_string,
							&err_pos),
						{ yyerror (&yylloc, conf, "Error setting Priority parameter.");
						  fprintf(stderr, "Error at position : %s\n", err_pos);
						  YYERROR; } );
			}
			;
			
tls_dh:			TLS_DH_BITS '=' INTEGER ';'
			{
				conf->cnf_sec_data.dh_bits = $3;
			}
			| TLS_DH_FILE '=' QSTRING ';'
			{
				FILE * fd;
				free(conf->cnf_sec_data.dh_file);
				conf->cnf_sec_data.dh_file = $3;
				fd = fopen($3, "r");
				if (fd == NULL) {
					int ret = errno;
					TRACE_DEBUG(INFO, "Unable to open DH file %s for reading: %s\n", $3, strerror(ret));
					yyerror (&yylloc, conf, "Error on file name"); 
					YYERROR;
				}
				fclose(fd);
			}
			;