/* Copyright (C) 2015 - 2017 National Aeronautics and Space Administration. All Foreign Rights are Reserved to the U.S. Government.

   This software is provided "as is" without any warranty of any, kind either express, implied, or statutory, including, but not
   limited to, any warranty that the software will conform to, specifications any implied warranties of merchantability, fitness
   for a particular purpose, and freedom from infringement, and any warranty that the documentation will conform to the program, or
   any warranty that the software will be error free.

   In no event shall NASA be liable for any damages, including, but not limited to direct, indirect, special or consequential damages,
   arising out of, resulting from, or in any way connected with the software or its documentation.  Whether or not based upon warranty,
   contract, tort or otherwise, and whether or not loss was sustained from, or arose out of the results of, or use of, the software,
   documentation or services provided hereunder

   ITC Team
   NASA IV&V
   ivv-itc@lists.nasa.gov
*/

#include <iomanip>
#include <limits>

#include <boost/algorithm/string.hpp>
#include <boost/tokenizer.hpp>
#include <boost/lexical_cast.hpp>

#include <ItcLogger/Logger.hpp>

#include <sim_42data_point.hpp>

namespace Nos3
{

    extern ItcLogger::Logger *sim_logger;

    /*************************************************************************
     * Constructors
     *************************************************************************/

    Sim42DataPoint::Sim42DataPoint(std::vector<std::string> &message) : _lines(message)
    {
        for (std::vector<std::string>::const_iterator iter = _lines.begin(); iter != _lines.end(); iter++) {
            size_t equals = iter->find("=");
            if (equals != std::string::npos) {
                std::string key(iter->substr(0, equals));
                boost::trim(key);
                std::string value(iter->substr(equals+1));
                boost::trim(value);
                _key_values.insert({key, value});
            } else if(iter->compare(0, 4, "TIME") == 0) {
                std::string value(iter->substr(4));
                boost::trim(value);
                _key_values.insert({"TIME", value});
                parse_time(value);
                long Month, Day;
                DOY2MD(std::stol(_key_values["YEAR"]), std::stol(_key_values["DOY"]), &Month, &Day);
                _key_values.insert({"MONTH", std::to_string(Month)});
                _key_values.insert({"DAY", std::to_string(Day)});
                _key_values.insert({"ABSTIME", 
                    std::to_string(DateToTime(std::stol(_key_values["YEAR"]), Month, Day, 
                    std::stol(_key_values["HOUR"]), std::stol(_key_values["MINUTE"]), std::stod(_key_values["SECOND"])))});
            } else {
                std::string key(*iter);
                boost::trim(key);
                _key_values.insert({key, ""});
            }
        }
        sim_logger->trace("Sim42DataPoint::Sim42DataPoint:  Constructed data point with:  %s", to_string().c_str());
        sim_logger->trace("Sim42DataPoint::Sim42DataPoint - key/values:");
        for (std::map<std::string, std::string>::const_iterator iter = _key_values.begin(); iter != _key_values.end(); iter++) {
            sim_logger->trace("  %s, %s", iter->first.c_str(), iter->second.c_str());
        }
    }

    /*************************************************************************
     * Accessors
     *************************************************************************/

    void Sim42DataPoint::parse_time(const std::string& value)
    {
        std::vector<std::string> tokens;
        std::istringstream iss(value);
        std::string token;
        while (std::getline(iss, token, '-')) {
            tokens.push_back(token);
        }
        std::string key = "YEAR";
        _key_values.insert({key, tokens[0]});
        key = "DOY";
        _key_values.insert({key, tokens[1]});
        std::string time(tokens[2]);

        tokens.clear();
        std::istringstream iss2(time);
        while (std::getline(iss2, token, ':')) {
            tokens.push_back(token);
        }
        key = "HOUR";
        _key_values.insert({key, tokens[0]});
        key = "MINUTE";
        _key_values.insert({key, tokens[1]});
        key = "SECOND";
        _key_values.insert({key, tokens[2]});
    }

    /**********************************************************************/
    /*  Find Month, Day, given Day of Year                                */
    /*  Ref. Jean Meeus, 'Astronomical Algorithms', QB51.3.E43M42, 1991.  */
    /*   This function is agnostic to the TT-to-UTC offset.  You get out  */
    /*   what you put in.                                                 */
    void Sim42DataPoint::DOY2MD(long Year, long DayOfYear, long *Month, long *Day)
    {
        long K;

        if (Year % 4 == 0) {
            K = 1;
        }
        else {
            K = 2;
        }

        if (DayOfYear < 32) {
            *Month = 1;
        }
        else {
            *Month = (long) (9.0*(K+DayOfYear)/275.0+0.98);
        }

        *Day = DayOfYear - 275*(*Month)/9 + K*(((*Month)+9)/12) + 30;

    }

    /**********************************************************************/
    /*  Convert Year, Month, Day, Hour, Minute and Second to              */
    /*  "Time", i.e. seconds elapsed since J2000 epoch.                   */
    /*  Year, Month, Day assumed in Gregorian calendar. (Not true < 1582) */
    /*  Ref. Jean Meeus, 'Astronomical Algorithms', QB51.3.E43M42, 1991.  */
    /*  This function is agnostic to the TT-to-UTC offset.  You get out   */
    /*  what you put in.                                                  */

    double Sim42DataPoint::DateToTime(long Year, long Month, long Day,
                long Hour, long Minute, double Second)
    {
        long A,B;
        double Days;
        
        if (Month < 3) {
            Year--;
            Month+=12;
        }

        A = Year/100;
        B = 2 - A + A/4;

        /* Days since J2000 Epoch (01 Jan 2000 12:00:00.0) */
        Days = floor(365.25*(Year-2000))
                    + floor(30.6001*(Month+1))
                    + Day + B - 50.5;

        /* Add fractional day */
        return(86400.0*Days + 3600.0*((double) Hour)
            + 60.0*((double) Minute) + Second);
    }

    std::string Sim42DataPoint::to_string(void) const
    {
        std::stringstream ss;

        ss << std::fixed << std::setfill(' ');
        ss << "42 Data Point: ";
        for (std::vector<std::string>::const_iterator it = _lines.begin(); it != _lines.end(); ++it) {
            ss << *it;
        }
        return ss.str();
    }

    std::string Sim42DataPoint::get_value_for_key(std::string key) {
        return _key_values[key];
    }

    /*************************************************************************
     * Static methods
     *************************************************************************/

    void Sim42DataPoint::parse_double_vector(const std::string& text, std::vector<double>& dv) 
    {
        dv.clear();
        std::string t = text;
        t.erase(std::remove(t.begin(), t.end(), '['), t.end());
        t.erase(std::remove(t.begin(), t.end(), ']'), t.end());
        std::istringstream iss(t);
        for (std::string s; iss >> s; )
            dv.push_back(std::stod(s));
    }
    

}
