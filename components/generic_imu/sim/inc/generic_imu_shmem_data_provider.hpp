#ifndef NOS3_GENERIC_IMUSHMEMDATAPROVIDER_HPP
#define NOS3_GENERIC_IMUSHMEMDATAPROVIDER_HPP

#include <boost/property_tree/ptree.hpp>
#include <ItcLogger/Logger.hpp>
#include <boost/interprocess/managed_shared_memory.hpp>
#include <generic_imu_data_point.hpp>
#include <sim_data_42socket_provider.hpp>
#include <blackboard_data.hpp>

namespace Nos3
{
    namespace bip = boost::interprocess;

    class Generic_imuShmemDataProvider : public SimIDataProvider
    {
    public:
        /* Constructors */
        Generic_imuShmemDataProvider(const boost::property_tree::ptree& config);

        /* Accessors */
        boost::shared_ptr<SimIDataPoint> get_data_point(void) const;

    private:
        /* Disallow these */
        ~Generic_imuShmemDataProvider(void) {};
        Generic_imuShmemDataProvider& operator=(const Generic_imuShmemDataProvider&) {return *this;};

        bip::mapped_region _shm_region;
        BlackboardData*    _blackboard_data;
    };
}

#endif
