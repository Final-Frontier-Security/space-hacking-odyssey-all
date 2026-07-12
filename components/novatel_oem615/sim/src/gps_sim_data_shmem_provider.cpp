/* Copyright (C) 2015 - 2025 National Aeronautics and Space Administration. All Foreign Rights are Reserved to the U.S. Government.

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

#include <ItcLogger/Logger.hpp>

#include <gps_sim_data_point.hpp>
#include <gps_sim_data_shmem_provider.hpp>

namespace Nos3
{
    REGISTER_DATA_PROVIDER(GPSSimDataShmemProvider,"GPS_SHMEM");

    extern ItcLogger::Logger *sim_logger;

    /*************************************************************************
     * Constructors
     *************************************************************************/

    GPSSimDataShmemProvider::GPSSimDataShmemProvider(const boost::property_tree::ptree& config)
        : SimIDataProvider(config)
    {
        const std::string shm_name = config.get("simulator.hardware-model.data-provider.shared-memory-name", "Blackboard");
        const size_t shm_size = sizeof(BlackboardData);
        bip::shared_memory_object shm(bip::open_or_create, shm_name.c_str(), bip::read_write);
        shm.truncate(shm_size);
        bip::mapped_region shm_region(shm, bip::read_write);
        _shm_region = std::move(shm_region); // don't le this go out of scope/get destroyed
        _blackboard_data = static_cast<BlackboardData*>(_shm_region.get_address());
        _sc = config.get("simulator.hardware-model.data-provider.spacecraft", 0);
        _gps = config.get("simulator.hardware-model.data-provider.GPS", 0);
        _leap_seconds = config.get("simulator.hardware-model.data-provider.leap-seconds", 37);
    }

    /*************************************************************************
     * Non-mutating public worker methods
     *************************************************************************/

    boost::shared_ptr<SimIDataPoint> GPSSimDataShmemProvider::get_data_point(void) const
    {
        sim_logger->trace("GPSSimDataShmemProvider::get_data_point:  Executed");
        
        boost::shared_ptr<GPSSimDataPoint> dp;
        {
            dp = boost::shared_ptr<GPSSimDataPoint>(
                new GPSSimDataPoint(_blackboard_data->AbsTime, _leap_seconds, _blackboard_data->GPSWeek, _blackboard_data->GPSSec, _blackboard_data->GPSFracSec,
                    _blackboard_data->GPSPosW, _blackboard_data->GPSVelW, _blackboard_data->GPSPosN, _blackboard_data->GPSVelN));
        }
        sim_logger->trace("GPSSimDataShmemProvider::get_data_point: %s", dp->to_string().c_str()); // log data in a man readable format
        return dp;
    }

    /*************************************************************************
     * Private helper methods
     *************************************************************************/

}
