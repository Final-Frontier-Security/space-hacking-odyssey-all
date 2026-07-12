#ifndef NOS3_GENERIC_MAGSHMEMDATAPROVIDER_HPP
#define NOS3_GENERIC_MAGSHMEMDATAPROVIDER_HPP

#include <boost/property_tree/ptree.hpp>
#include <ItcLogger/Logger.hpp>
#include <boost/interprocess/managed_shared_memory.hpp>
#include <generic_mag_data_point.hpp>
#include <sim_i_data_provider.hpp>
#include <blackboard_data.hpp>

namespace Nos3
{
    namespace bip = boost::interprocess;

    class Generic_magShmemDataProvider : public SimIDataProvider
    {
    public:
        /* Constructors */
        Generic_magShmemDataProvider(const boost::property_tree::ptree& config);

        /* Accessors */
        boost::shared_ptr<SimIDataPoint> get_data_point(void) const;

    private:
        /* Disallow these */
        ~Generic_magShmemDataProvider(void) {};
        Generic_magShmemDataProvider& operator=(const Generic_magShmemDataProvider&) {return *this;};

        bip::mapped_region _shm_region;
        BlackboardData*    _blackboard_data;
    };
}

#endif
