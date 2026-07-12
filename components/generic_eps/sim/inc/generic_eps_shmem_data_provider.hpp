#ifndef NOS3_GENERIC_EPS42DATAPROVIDER_HPP
#define NOS3_GENERIC_EPS42DATAPROVIDER_HPP

#include <boost/property_tree/ptree.hpp>
#include <ItcLogger/Logger.hpp>
#include <boost/interprocess/managed_shared_memory.hpp>
#include <generic_eps_data_point.hpp>
#include <sim_data_42socket_provider.hpp>
#include <blackboard_data.hpp>

namespace Nos3
{
    namespace bip = boost::interprocess;

    class Generic_epsShmemDataProvider : public SimIDataProvider
    {
    public:
        /* Constructors */
        Generic_epsShmemDataProvider(const boost::property_tree::ptree& config);

        /* Accessors */
        boost::shared_ptr<SimIDataPoint> get_data_point(void) const;

    private:
        /* Disallow these */
        ~Generic_epsShmemDataProvider(void) {};
        Generic_epsShmemDataProvider& operator=(const Generic_epsShmemDataProvider&) {return *this;};

        int16_t _orb; // Which orbit number to parse out of 42 data
        int16_t _sc;  /* Which spacecraft number to parse out of 42 data */
        bip::mapped_region _shm_region;
        BlackboardData*    _blackboard_data;
    };
}

#endif
