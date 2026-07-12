#ifndef NOS3_GENERIC_CSS42DATAPROVIDER_HPP
#define NOS3_GENERIC_CSS42DATAPROVIDER_HPP

#include <boost/property_tree/ptree.hpp>
#include <ItcLogger/Logger.hpp>
#include <boost/interprocess/managed_shared_memory.hpp>
#include <generic_css_data_point.hpp>
#include <sim_data_42socket_provider.hpp>
#include <blackboard_data.hpp>

namespace Nos3
{
    namespace bip = boost::interprocess;

    /* Standard for a 42 data provider */
    class Generic_cssShmemDataProvider : public SimIDataProvider
    {
    public:
        /* Constructors */
        Generic_cssShmemDataProvider(const boost::property_tree::ptree& config);

        /* Accessors */
        boost::shared_ptr<SimIDataPoint> get_data_point(void) const;

    private:
        /* Disallow these */
        ~Generic_cssShmemDataProvider(void) {};
        Generic_cssShmemDataProvider& operator=(const Generic_cssShmemDataProvider&) {return *this;};

        int16_t _sc;  /* Which spacecraft number to parse out of 42 data */
        double _scale_factor; /* Corresponds to the CSS Scale Factor from 42 */

        bip::mapped_region _shm_region;
        BlackboardData*    _blackboard_data;
    };
}

#endif
