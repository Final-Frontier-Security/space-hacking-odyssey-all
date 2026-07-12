#include <ItcLogger/Logger.hpp>
#include <blackboard_data_point.hpp>

namespace Nos3
{
    extern ItcLogger::Logger *sim_logger;

    BlackboardDataPoint::BlackboardDataPoint(int16_t spacecraft, const boost::shared_ptr<Sim42DataPoint> dp) : _dp(*dp), _sc(spacecraft), _not_parsed(true)
    {
        sim_logger->trace("BlackboardDataPoint::BlackboardDataPoint:  42 Constructor executed");

        /* Initialize data */
    }
    
    void BlackboardDataPoint::do_parsing(void) const
    {
        try {
            /*
            ** Declare 42 telemetry string prefix
            ** 42 variables defined in `42/Include/42types.h`
            ** 42 data stream defined in `42/Source/IPC/SimWriteToSocket.c`
            */
            std::string key;
            std::string values;
            std::vector<double> data;
            data.reserve(6);

            key = "";
            key.append("SC[").append(std::to_string(_sc)).append("].svb"); // SC[N].svb
            parse_double_vector(_dp.get_value_for_key(key), data);
            _svb[0] = data[0];
            _svb[1] = data[1];
            _svb[2] = data[2];

            key = "";
            key.append("SC[").append(std::to_string(_sc)).append("].bvb"); // SC[N].bvb
            parse_double_vector(_dp.get_value_for_key(key), data);
            _bvb[0] = data[0];
            _bvb[1] = data[1];
            _bvb[2] = data[2];

            key = "";
            key.append("SC[").append(std::to_string(_sc)).append("].Hvb"); // SC[N].Hvb
            parse_double_vector(_dp.get_value_for_key(key), data);
            _Hvb[0] = data[0];
            _Hvb[1] = data[1];
            _Hvb[2] = data[2];

            key = "";
            key.append("SC[").append(std::to_string(_sc)).append("].Gyro[0].TrueRate"); // SC[N].Gyro[0].TrueRate
            _GyroRate[0] = std::stof(_dp.get_value_for_key(key));
            key = "";
            key.append("SC[").append(std::to_string(_sc)).append("].Gyro[1].TrueRate"); // SC[N].Gyro[1].TrueRate
            _GyroRate[1] = std::stof(_dp.get_value_for_key(key));
            key = "";
            key.append("SC[").append(std::to_string(_sc)).append("].Gyro[2].TrueRate"); // SC[N].Gyro[2].TrueRate
            _GyroRate[2] = std::stof(_dp.get_value_for_key(key));

            key = "";
            key.append("SC[").append(std::to_string(_sc)).append("].CSS[0].Valid"); // SC[N].CSS[0].Valid
            _CSSValid[0] = std::stof(_dp.get_value_for_key(key));
            key = "";
            key.append("SC[").append(std::to_string(_sc)).append("].CSS[1].Valid"); // SC[N].CSS[1].Valid
            _CSSValid[1] = std::stof(_dp.get_value_for_key(key));
            key = "";
            key.append("SC[").append(std::to_string(_sc)).append("].CSS[2].Valid"); // SC[N].CSS[2].Valid
            _CSSValid[2] = std::stof(_dp.get_value_for_key(key));
            key = "";
            key.append("SC[").append(std::to_string(_sc)).append("].CSS[3].Valid"); // SC[N].CSS[3].Valid
            _CSSValid[3] = std::stof(_dp.get_value_for_key(key));
            key = "";
            key.append("SC[").append(std::to_string(_sc)).append("].CSS[4].Valid"); // SC[N].CSS[4].Valid
            _CSSValid[4] = std::stof(_dp.get_value_for_key(key));
            key = "";
            key.append("SC[").append(std::to_string(_sc)).append("].CSS[5].Valid"); // SC[N].CSS[5].Valid
            _CSSValid[5] = std::stof(_dp.get_value_for_key(key));

            key = "";
            key.append("SC[").append(std::to_string(_sc)).append("].CSS[0].Illum"); // SC[N].CSS[0].Illum
            _CSSIllum[0] = std::stof(_dp.get_value_for_key(key));
            key = "";
            key.append("SC[").append(std::to_string(_sc)).append("].CSS[1].Illum"); // SC[N].CSS[1].Illum
            _CSSIllum[1] = std::stof(_dp.get_value_for_key(key));
            key = "";
            key.append("SC[").append(std::to_string(_sc)).append("].CSS[2].Illum"); // SC[N].CSS[2].Illum
            _CSSIllum[2] = std::stof(_dp.get_value_for_key(key));
            key = "";
            key.append("SC[").append(std::to_string(_sc)).append("].CSS[3].Illum"); // SC[N].CSS[3].Illum
            _CSSIllum[3] = std::stof(_dp.get_value_for_key(key));
            key = "";
            key.append("SC[").append(std::to_string(_sc)).append("].CSS[4].Illum"); // SC[N].CSS[4].Illum
            _CSSIllum[4] = std::stof(_dp.get_value_for_key(key));
            key = "";
            key.append("SC[").append(std::to_string(_sc)).append("].CSS[5].Illum"); // SC[N].CSS[5].Illum
            _CSSIllum[5] = std::stof(_dp.get_value_for_key(key));

            key = "";
            key.append("SC[").append(std::to_string(_sc)).append("].FSS[0].Valid"); // SC[N].FSS[0].Valid
            _FSSValid = std::stof(_dp.get_value_for_key(key));

            key = "";
            key.append("SC[").append(std::to_string(_sc)).append("].FSS[0].SunAng"); // SC[N].FSS[0].SunAng
            parse_double_vector(_dp.get_value_for_key(key), data);
            _FSSSunAng[0] = data[0];
            _FSSSunAng[1] = data[1];

            key = "";
            key.append("SC[").append(std::to_string(_sc)).append("].ST[0].Valid"); // SC[N].ST[0].Valid
            _STValid = std::stof(_dp.get_value_for_key(key));

            key = "";
            key.append("SC[").append(std::to_string(_sc)).append("].ST[0].qn"); // SC[N].ST[0].qn
            parse_double_vector(_dp.get_value_for_key(key), data);
            _STqn[0] = data[0];
            _STqn[1] = data[1];
            _STqn[2] = data[2];
            _STqn[3] = data[3];

            _AbsTime = std::stod(_dp.get_value_for_key("ABSTIME"));

            key = "";
            key.append("SC[").append(std::to_string(_sc)).append("].GPS[0].Week"); // SC[N].GPS[0].Week
            _GPSWeek = std::stof(_dp.get_value_for_key(key));

            key = "";
            key.append("SC[").append(std::to_string(_sc)).append("].GPS[0].Sec"); // SC[N].GPS[0].GPSSec
            float seconds = std::stof(_dp.get_value_for_key(key));
            _GPSSec = seconds;
            _GPSFracSec = seconds - _GPSSec;

            key = "";
            key.append("SC[").append(std::to_string(_sc)).append("].GPS[0].PosN"); // SC[N].GPS[0].PosN
            parse_double_vector(_dp.get_value_for_key(key), data);
            _GPSPosN[0] = data[0];
            _GPSPosN[1] = data[1];
            _GPSPosN[2] = data[2];

            key = "";
            key.append("SC[").append(std::to_string(_sc)).append("].GPS[0].VelN"); // SC[N].GPS[0].VelN
            parse_double_vector(_dp.get_value_for_key(key), data);
            _GPSVelN[0] = data[0];
            _GPSVelN[1] = data[1];
            _GPSVelN[2] = data[2];

            key = "";
            key.append("SC[").append(std::to_string(_sc)).append("].GPS[0].PosW"); // SC[N].GPS[0].PosW
            parse_double_vector(_dp.get_value_for_key(key), data);
            _GPSPosW[0] = data[0];
            _GPSPosW[1] = data[1];
            _GPSPosW[2] = data[2];

            key = "";
            key.append("SC[").append(std::to_string(_sc)).append("].GPS[0].VelW"); // SC[N].GPS[0].VelW
            parse_double_vector(_dp.get_value_for_key(key), data);
            _GPSVelW[0] = data[0];
            _GPSVelW[1] = data[1];
            _GPSVelW[2] = data[2];

            key = "";
            key.append("SC[").append(std::to_string(_sc)).append("].Accel[0].TrueAcc"); // SC[N].Accel[0].TrueAcc
            _AccelAcc[0] = std::stof(_dp.get_value_for_key(key));
            key = "";
            key.append("SC[").append(std::to_string(_sc)).append("].Accel[1].TrueAcc"); // SC[N].Accel[1].TrueAcc
            _AccelAcc[1] = std::stof(_dp.get_value_for_key(key));
            key = "";
            key.append("SC[").append(std::to_string(_sc)).append("].Accel[2].TrueAcc"); // SC[N].Accel[2].TrueAcc
            _AccelAcc[2] = std::stof(_dp.get_value_for_key(key));

            key = "";
            key.append("SC[").append(std::to_string(_sc)).append("].Whl[0].H"); // SC[N].Whl[0].H
            _WhlH[0] = std::stof(_dp.get_value_for_key(key));
            key = "";
            key.append("SC[").append(std::to_string(_sc)).append("].Whl[1].H"); // SC[N].Whl[1].H
            _WhlH[1] = std::stof(_dp.get_value_for_key(key));
            key = "";
            key.append("SC[").append(std::to_string(_sc)).append("].Whl[2].H"); // SC[N].Whl[2].H
            _WhlH[2] = std::stof(_dp.get_value_for_key(key));


            _not_parsed = false;

            /* Debug print */
            sim_logger->trace("BlackboardDataPoint::BlackboardDataPoint:  Parsed point = ");
        } catch (const std::exception &e) {
            sim_logger->error("BlackboardDataPoint::BlackboardDataPoint:  Error parsing point.  Error=%s.  Data=%s", e.what(), to_string().c_str());
        }
    }

    /* Used for printing a representation of the data point */
    std::string BlackboardDataPoint::to_string(void) const
    {
        sim_logger->trace("BlackboardDataPoint::to_string:  Executed");
        
        std::stringstream ss;

        ss << std::fixed << std::setfill(' ');
        ss << "Blackboard Data Point: ";
        ss << std::setprecision(std::numeric_limits<double>::digits10); /* Full double precision */
        ss << " Blackboard Data: ";
        std::vector<std::string> lines = get_lines();
        for (std::vector<std::string>::iterator it = lines.begin(); it != lines.end(); it++) {
            ss << *it;
        }

        return ss.str();
    }
} /* namespace Nos3 */
