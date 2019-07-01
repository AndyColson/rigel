/* include file for using the config file tools */

/* describes each parameter to find */
typedef enum
{
    CFG_INT, CFG_DBL, CFG_STR
} CfgType;
typedef struct
{
    char *name;     /* name of parameter */
    CfgType type;   /* type */
    void *valp;     /* pointer to value */
    int slen;       /* if CFG_STR, length of array at valp */
    int found;      /* set if found */
}  CfgEntry;

extern int readCfgFile (int trace, char *fn, CfgEntry cea[], int ncea);
extern int read1CfgEntry (int trace, char *fn, char *name, CfgType t,
                          void *vp, int slen);

