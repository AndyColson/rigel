/* manage a config file of name=value pairs.
 * see nextPair for a full description of syntax.
 * also utility functions to manage filter.cfg.
 */

#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>
#include <string.h>
#include <errno.h>
#include <time.h>
#include <math.h>
#include <sqlite3.h>

#include "configfile.h"
#include "strops.h"
#include "telenv.h"
/* stuff specifically for filter.cfg is down a ways... */

/* read the given list of params from the given config file.
 * return number of entries found, or -1 if can not even open file.
 * if trace each entry found is traced to stderr as "filename: name = value".
 * N.B. it is the *last* entry in the file that counts.
 */
int
readCfgFile (int trace, char *cfn, CfgEntry cea[], int ncea)
{
	sqlite3 *db;
    CfgEntry *cep, *lcea = cea+ncea;
    char valu[1024];
    int nfound;
	int rc;

	snprintf(valu, sizeof(valu), "%s/%s", getenv ("TELHOME"), "config.sqlite");

    //daemonLog ("file %s", valu);

	rc = sqlite3_open_v2(valu, &db, SQLITE_OPEN_READONLY, NULL);
	//daemonLog("sqlite %d", rc);

	if (rc)
	{
		daemonLog("cant open database: %s", sqlite3_errmsg(db));
		sqlite3_close(db);
		return -1;
	}

	int len = snprintf(valu, sizeof(valu), "select value from config where app = '%s' and key = $1", cfn);

	sqlite3_stmt *q;

	rc = sqlite3_prepare_v3(db, valu, len, 0, &q, NULL);
	if (rc)
	{
		daemonLog("prepare failed: %i", rc);
		sqlite3_close(db);
		return -1;
	}

    /* reset found flags */
    for (cep = cea; cep < lcea; cep++)
        cep->found = 0;

    /* for each pair in file
     *   fill if in cea list
     */
    nfound = 0;
	for (cep = cea; cep < lcea; cep++)
	{
		sqlite3_bind_text(q, 1, cep->name, strlen(cep->name),  SQLITE_STATIC);

		int step = sqlite3_step(q);

		if (step == SQLITE_ROW)
		{
			int tmpi;
			double tmpf;
			switch (cep->type)
			{
				case CFG_INT:
					tmpi = sqlite3_column_int(q, 0);
					*((int *)cep->valp) = tmpi;
					daemonLog ("read int cfg app [%s] key [%s] = %d",cfn, cep->name, tmpi);
					break;
				case CFG_DBL:
					tmpf = sqlite3_column_double(q, 0);
					*((double *)cep->valp) = tmpf;
					daemonLog ("read dbl cfg app [%s] key [%s] = %lf",cfn, cep->name, tmpf);
					break;
				case CFG_STR:
					strncpy ((char *)(cep->valp), sqlite3_column_text(q, 0), cep->slen);
					daemonLog ("read str cfg app [%s] key [%s] = %s",cfn, cep->name, (char *)(cep->valp));
					break;
				default:
					daemonLog ("cfg file, app %s key %s bad type: %d",cfn, cep->name, cep->type);
					exit(1);
			}
			if (!cep->found)
			{
				cep->found = 1;
				nfound++;   /* just count once */
			}
		}
		else
		{
			daemonLog ("read cfg app [%s] key [%s] NOT FOUND",cfn, cep->name);
		}
		sqlite3_reset(q);
	}

	sqlite3_finalize(q);
	sqlite3_close(db);

    return (nfound);
}

/* handy wrapper to read 1 config file entry.
 * return 0 if found, else -1.
 */
int
read1CfgEntry (int trace, char *fn, char *name, CfgType t, void *vp, int slen)
{
    CfgEntry e;

    e.name = name;
    e.type = t;
    e.valp = vp;
    e.slen = slen;

    return (readCfgFile (trace, fn, &e, 1) == 1 ? 0 : -1);
}

/* handy utility to print an error message describing what went wrong with
 * a call to readCfgFile().
 * fn is the offending file name.
 * retval is the return value from readCfgFile().
 * pf is a printf-style function to call. use daemonLog if NULL.
 * cea[]/ncea are the same as passed to readCfgFile().
 */
void
cfgFileError (char *fn, int retval, CfgPrFp pf, CfgEntry cea[], int ncea)
{
    int i;

    if (!pf)
        pf = (CfgPrFp) daemonLog;

    if (retval < 0)
    {
        (*pf) ("%s: %s\n", basenm(fn), strerror(errno));
    }
    else
    {
        for (i = 0; i < ncea && retval < ncea; i++)
        {
            if (!cea[i].found)
            {
                (*pf) ("%s: %s not found\n", basenm(fn), cea[i].name);
                retval++;
            }
        }
    }
}

/* search cea[] for name and return 1 if present and marked found, return 0 if
 * present but not marked found, return -1 if not present at all.
 */
int
cfgFound (char *name, CfgEntry cea[], int ncea)
{
    CfgEntry *cep, *lcea = cea+ncea;
    int found = 0;
    int present = 0;

    for (cep = cea; cep < lcea; cep++)
        if (strcmp (name, cep->name) == 0)
        {
            present = 1;
            found = cep->found;
            break;
        }

    return (present ? (found ? 1 : 0) : -1);
}

