# GPGEN_SQLLDR

----

## Description :

The gpgen_sqlldr is an sql script, created under Affero General Public License v3.0 to generate a .dat and .ctl
files for oracle utility sqlldr. Basically permits to export a table with the possibility to filter data.

Script requiered two parameters :

       @gpgen_sqlldr.sql <TABLE NAME> <CONDITION>  

ex.

       @gpgen_sqlldr.sql users 1=1

Will be created these files :

      users.ctl
      users.dat

 To use with :

        sqlldr userid={user}/{password} control=users.ctl log=users.log
  
----

## Compatibility :

ORACLE 8 or upper


----

## Prerequisites :

Script sql need to have write permission in directory where it is executed.

----

## License :

This project is licensed under the Affero General Public License v3.0 - see the [LICENSE](LICENSE) file for details  
